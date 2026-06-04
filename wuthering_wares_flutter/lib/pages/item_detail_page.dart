import 'package:flutter/material.dart';

import '../apis/api.dart';
import '../models/catalog_item.dart';
import '../utils/auth_store.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/action_buttons.dart';
import '../widgets/interactive_surface.dart';

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({
    super.key,
    required this.item,
    required this.adminMode,
    required this.onBack,
    required this.onCartAdded,
    required this.onTokenInvalid,
    required this.showMessage,
  });

  final CatalogItem item;
  final bool adminMode;
  final VoidCallback onBack;
  final VoidCallback onCartAdded;
  final VoidCallback onTokenInvalid;
  final void Function(String message, {required bool success}) showMessage;

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  int _quantity = 1;
  bool _adding = false;

  Future<void> _addToCart() async {
    final token = await AuthStore.token;
    if (token == null) {
      _tokenInvalid();
      return;
    }
    setState(() => _adding = true);
    final result = await Api.addToCart(token, widget.item.id, _quantity);
    if (!mounted) return;
    setState(() => _adding = false);
    if (result.message == tokenMissingMessage) {
      _tokenInvalid();
      return;
    }
    widget.showMessage(
      result.message.isEmpty
          ? (result.success
                ? 'Item berhasil ditambahkan ke keranjang.'
                : 'Gagal menambahkan item ke keranjang.')
          : result.message,
      success: result.success,
    );
    if (result.success) widget.onCartAdded();
  }

  void _tokenInvalid() {
    widget.showMessage(tokenMissingMessage, success: false);
    widget.onTokenInvalid();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Kembali'),
              ),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 1.18,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: item.image == null
                      ? const Icon(
                          Icons.image_outlined,
                          color: AppColors.textSecondary,
                          size: 54,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            '$apiBase${item.image}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              color: AppColors.textSecondary,
                              size: 54,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                item.name.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 22),
              DetailRow(label: 'ID Item', value: item.id),
              DetailRow(label: 'Nama', value: item.name),
              DetailRow(label: 'Tipe', value: typeLabel(item.type)),
              DetailRow(label: 'Stok', value: '${item.stock} Unit'),
              DetailRow(label: 'Harga', value: formatRupiah(item.price)),
              DetailRow(
                label: 'Rarity',
                child: RarityText(rarity: item.rarity),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.input,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (!widget.adminMode) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Text(
                      'Jumlah',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 20),
                    QuantityButton(
                      icon: Icons.remove,
                      onTap: () => setState(
                        () => _quantity = (_quantity - 1).clamp(1, 999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    QuantityButton(
                      icon: Icons.add,
                      onTap: () => setState(() => _quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryActionButton(
                  text:
                      'TAMBAH KE KERANJANG (${formatRupiah(item.price * _quantity)})',
                  loading: _adding,
                  onPressed: _addToCart,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
            ),
          ),
        ),
        Expanded(
          child:
              child ??
              Text(
                value ?? '-',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                ),
              ),
        ),
      ],
    ),
  );
}

class RarityText extends StatelessWidget {
  const RarityText({super.key, required this.rarity});

  final int rarity;

  @override
  Widget build(BuildContext context) {
    final color = switch (rarity) {
      5 => const Color(0xFFFFD65A),
      4 => const Color(0xFFB889FF),
      3 => const Color(0xFF55A9FF),
      2 => const Color(0xFF55E087),
      _ => AppColors.textPrimary,
    };
    return Text(
      '$rarity Bintang',
      style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800),
    );
  }
}

class QuantityButton extends StatelessWidget {
  const QuantityButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    onTap: onTap,
    borderRadius: 22,
    borderColor: AppColors.stroke,
    hoverBorderColor: AppColors.cyan,
    hoverColor: AppColors.cyan.withValues(alpha: 0.08),
    child: SizedBox(
      width: 44,
      height: 44,
      child: Icon(icon, color: AppColors.cyan),
    ),
  );
}
