import 'package:flutter/material.dart';

import '../apis/api.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../utils/auth_store.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/action_buttons.dart';
import '../widgets/snap_payment_dialog.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    required this.onTokenInvalid,
    required this.showMessage,
  });

  final VoidCallback onTokenInvalid;
  final void Function(String message, {required bool success}) showMessage;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  CartData? _cart;
  bool _loading = true;
  bool _checkingOut = false;
  String? _busyCartId;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<String?> _token() async {
    final token = await AuthStore.token;
    if (token == null) _tokenInvalid();
    return token;
  }

  Future<void> _loadCart() async {
    final token = await _token();
    if (token == null) return;
    setState(() => _loading = true);
    final result = await Api.cart(token);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.message == tokenMissingMessage) {
      _tokenInvalid();
      return;
    }
    if (!result.success) {
      _show(result.message.isEmpty ? 'Gagal memuat keranjang.' : result.message, false);
      return;
    }
    setState(() {
      _cart = result.data is Map<String, dynamic>
          ? CartData.fromJson(result.data as Map<String, dynamic>)
          : const CartData(
              items: [],
              summary: CartSummary(
                totalItems: 0,
                totalPrice: 0,
                tax: 0,
                grandTotal: 0,
              ),
            );
    });
  }

  Future<void> _deleteItem(CartItem item) async {
    final token = await _token();
    if (token == null) return;
    setState(() => _busyCartId = item.cartId);
    final result = await Api.deleteCartItem(token, item.cartId);
    if (!mounted) return;
    setState(() => _busyCartId = null);
    if (result.message == tokenMissingMessage) {
      _tokenInvalid();
      return;
    }
    if (!result.success) {
      _show(result.message.isEmpty ? 'Gagal menghapus item keranjang.' : result.message, false);
      return;
    }
    await _loadCart();
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    if (quantity < 1 || quantity == item.quantity) return;
    final token = await _token();
    if (token == null) return;
    setState(() => _busyCartId = item.cartId);
    final result = await Api.updateCartQuantity(token, item.cartId, quantity);
    if (!mounted) return;
    setState(() => _busyCartId = null);
    if (result.message == tokenMissingMessage) {
      _tokenInvalid();
      return;
    }
    if (!result.success) {
      _show(result.message.isEmpty ? 'Gagal memperbarui jumlah item.' : result.message, false);
      return;
    }
    await _loadCart();
  }

  Future<void> _checkout() async {
    final token = await _token();
    if (token == null) return;
    setState(() => _checkingOut = true);
    final result = await Api.checkout(token);
    if (!mounted) return;
    setState(() => _checkingOut = false);
    if (result.message == tokenMissingMessage) {
      _tokenInvalid();
      return;
    }
    if (!result.success) {
      _show(result.message.isEmpty ? 'Checkout gagal.' : result.message, false);
      return;
    }
    if (result.data is! Map<String, dynamic>) {
      _show('Data pembayaran tidak valid.', false);
      return;
    }
    await showSnapPaymentDialog(
      context: context,
      payment: CheckoutData.fromJson(result.data as Map<String, dynamic>),
      message: result.message,
      showMessage: widget.showMessage,
    );
    if (mounted) await _loadCart();
  }

  void _show(String message, bool success) {
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

  @override
  Widget build(BuildContext context) {
    final cart = _cart;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KERANJANG',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kelola item sebelum melanjutkan pembayaran.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
                );
              }
              if (cart == null || cart.items.isEmpty) {
                return const Center(
                  child: Text(
                    'Tidak ada item.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 17),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 18),
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return CartItemCard(
                    item: item,
                    busy: _busyCartId == item.cartId,
                    onDelete: () => _deleteItem(item),
                    onIncrease: () {
                      final maxStock = item.stock > 0 ? item.stock : item.quantity + 1;
                      _updateQuantity(item, (item.quantity + 1).clamp(1, maxStock));
                    },
                    onDecrease: () => _updateQuantity(item, item.quantity - 1),
                  );
                },
              );
            },
          ),
        ),
        if (!_loading && cart != null && cart.items.isNotEmpty) ...[
          CartSummaryPanel(summary: cart.summary),
          const SizedBox(height: 14),
          PrimaryActionButton(
            text: 'LANJUTKAN MEMBAYAR',
            loading: _checkingOut,
            onPressed: _checkout,
          ),
          const SizedBox(height: 94),
        ],
      ],
    );
  }
}

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.busy,
    required this.onDelete,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartItem item;
  final bool busy;
  final VoidCallback onDelete;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final image = item.image == null ? null : '$apiBase${item.image}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 82,
              height: 82,
              color: AppColors.input,
              child: image == null
                  ? const Icon(Icons.image_outlined, color: AppColors.textMuted)
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  typeLabel(item.type),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(item.price),
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    QuantityIconButton(
                      icon: Icons.remove,
                      enabled: !busy && item.quantity > 1,
                      onTap: onDecrease,
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    QuantityIconButton(
                      icon: Icons.add,
                      enabled: !busy && (item.stock <= 0 || item.quantity < item.stock),
                      onTap: onIncrease,
                    ),
                    const Spacer(),
                    if (busy)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.cyan,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      IconButton(
                        tooltip: 'Hapus item',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, color: AppColors.yellow),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityIconButton extends StatelessWidget {
  const QuantityIconButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    height: 42,
    child: IconButton(
      onPressed: enabled ? onTap : null,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.cyan.withValues(alpha: enabled ? 0.12 : 0.04),
        foregroundColor: enabled ? AppColors.cyan : AppColors.textMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
    ),
  );
}

class CartSummaryPanel extends StatelessWidget {
  const CartSummaryPanel({super.key, required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.input,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.stroke),
    ),
    child: Column(
      children: [
        SummaryRow(label: 'Harga sebelum pajak', value: formatRupiah(summary.totalPrice)),
        SummaryRow(label: 'Pajak 5%', value: formatRupiah(summary.tax)),
        const Divider(color: AppColors.stroke, height: 22),
        SummaryRow(
          label: 'Harga setelah pajak',
          value: formatRupiah(summary.grandTotal),
          highlight: true,
        ),
      ],
    ),
  );
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: highlight ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.cyan : AppColors.textPrimary,
            fontSize: highlight ? 18 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
