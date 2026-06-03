import 'package:flutter/material.dart';

import '../apis/api.dart';
import '../models/catalog_item.dart';
import '../models/user.dart';
import '../utils/auth_store.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/brand_header.dart';
import 'admin_catalog_page.dart';
import 'catalog_page.dart';
import 'item_detail_page.dart';
import 'item_form_page.dart';
import 'profile_page.dart';
import 'simple_page.dart';

enum MainTab { catalog, payment, cart, profile }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.initialTab,
    required this.bindRefreshKey,
    required this.onTokenInvalid,
    required this.onLogout,
    required this.showMessage,
  });

  final MainTab initialTab;
  final int bindRefreshKey;
  final VoidCallback onTokenInvalid;
  final VoidCallback onLogout;
  final void Function(String message, {required bool success}) showMessage;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  User? _user;
  MainTab _tab = MainTab.catalog;
  ItemFilter _filter = ItemFilter.all;
  String _search = '';
  List<CatalogItem> _items = const [];
  CatalogItem? _detailItem;
  CatalogItem? _editItem;
  bool _showAdd = false;
  bool _loadingUser = true;
  bool _loadingItems = false;
  String? _error;

  bool get _isAdmin => _user?.role == 'admin';

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    loadUser();
    _loadItems();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bindRefreshKey != oldWidget.bindRefreshKey) {
      loadUser();
    }
    if (widget.initialTab != oldWidget.initialTab) {
      setState(() => _tab = widget.initialTab);
    }
  }

  Future<void> loadUser() async {
    final token = await AuthStore.token;
    if (token == null) {
      _tokenInvalid();
      return;
    }
    final result = await Api.me(token);
    if (!mounted) return;
    setState(() => _loadingUser = false);
    if (result.success && result.user != null) {
      setState(() => _user = result.user);
      return;
    }
    _handleApiMessage(
      result.message.isEmpty ? 'Gagal memuat data pengguna.' : result.message,
      false,
    );
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    final result = await Api.items(_filter.type);
    if (!mounted) return;
    setState(() {
      _loadingItems = false;
      if (result.success) {
        _items = result.items;
        _error = null;
      } else {
        _error = result.message.isEmpty ? 'Gagal memuat item.' : result.message;
      }
    });
  }

  Future<void> _deleteItem(CatalogItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text(
          'Hapus Item',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Hapus ${item.name}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = await AuthStore.token;
    if (token == null) {
      _tokenInvalid();
      return;
    }
    final result = await Api.deleteItem(token, item.id);
    _handleApiMessage(
      result.message.isEmpty
          ? (result.success
                ? 'Item berhasil dihapus.'
                : 'Gagal menghapus item.')
          : result.message,
      result.success,
    );
    if (result.success) _loadItems();
  }

  void _handleApiMessage(String message, bool success) {
    if (message == tokenMissingMessage) {
      _tokenInvalid();
      return;
    }
    widget.showMessage(message, success: success);
  }

  void _tokenInvalid() {
    widget.showMessage(tokenMissingMessage, success: false);
    widget.onTokenInvalid();
  }

  List<CatalogItem> get _visibleItems {
    final keyword = _search.trim().toLowerCase();
    if (keyword.isEmpty) return _items;
    return _items
        .where(
          (item) =>
              item.name.toLowerCase().contains(keyword) ||
              item.type.toLowerCase().contains(keyword) ||
              item.id.toLowerCase().contains(keyword),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_showAdd || _editItem != null) {
      return ItemFormPage(
        editItem: _editItem,
        onBack: () => setState(() {
          _showAdd = false;
          _editItem = null;
        }),
        onSaved: () {
          setState(() {
            _showAdd = false;
            _editItem = null;
            _tab = MainTab.catalog;
          });
          _loadItems();
        },
        onTokenInvalid: widget.onTokenInvalid,
        showMessage: widget.showMessage,
      );
    }
    if (_detailItem != null) {
      return ItemDetailPage(
        item: _detailItem!,
        adminMode: _isAdmin,
        onBack: () => setState(() => _detailItem = null),
      );
    }
    return Scaffold(
      bottomNavigationBar: BottomNav(
        selected: _tab,
        onSelected: (tab) => setState(() => _tab = tab),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_tab == MainTab.catalog && !_isAdmin) const BrandHeader(),
              if (_tab == MainTab.catalog &&
                  !_isAdmin &&
                  !_loadingUser &&
                  _user != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Halo, ${_user!.fullName}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
              if (_tab == MainTab.catalog && !_isAdmin)
                const SizedBox(height: 20),
              Expanded(child: _buildTab()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab() {
    if (_isAdmin && _tab == MainTab.catalog) {
      return AdminCatalogPage(
        filter: _filter,
        onFilter: (filter) {
          setState(() => _filter = filter);
          _loadItems();
        },
        search: _search,
        onSearch: (value) => setState(() => _search = value),
        loading: _loadingItems,
        error: _error,
        items: _visibleItems,
        onAdd: () => setState(() => _showAdd = true),
        onEdit: (item) => setState(() => _editItem = item),
        onDelete: _deleteItem,
        onDetail: (item) => setState(() => _detailItem = item),
      );
    }
    return switch (_tab) {
      MainTab.catalog => CatalogPage(
        filter: _filter,
        onFilter: (filter) {
          setState(() => _filter = filter);
          _loadItems();
        },
        search: _search,
        onSearch: (value) => setState(() => _search = value),
        loading: _loadingItems,
        error: _error,
        items: _visibleItems,
        onDetail: (item) => setState(() => _detailItem = item),
      ),
      MainTab.payment => const SimplePage(
        title: 'Pembayaran',
        description: 'Riwayat dan status pembayaran akan ditampilkan di sini.',
      ),
      MainTab.cart => const SimplePage(
        title: 'Keranjang',
        description: 'Item yang dipilih akan masuk ke halaman keranjang.',
      ),
      MainTab.profile => ProfilePage(
        user: _user,
        onUserChanged: (user) => setState(() => _user = user),
        onTokenInvalid: widget.onTokenInvalid,
        onLogout: widget.onLogout,
        showMessage: widget.showMessage,
      ),
    };
  }
}
