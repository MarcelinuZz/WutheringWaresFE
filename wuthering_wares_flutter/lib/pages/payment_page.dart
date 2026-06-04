import 'package:flutter/material.dart';

import '../apis/api.dart';
import '../models/order.dart';
import '../utils/auth_store.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/snap_payment_dialog.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.onTokenInvalid,
    required this.showMessage,
  });

  final VoidCallback onTokenInvalid;
  final void Function(String message, {required bool success}) showMessage;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  List<OrderSummary> _orders = const [];
  bool _loading = true;
  String? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<String?> _token() async {
    final token = await AuthStore.token;
    if (token == null) _tokenInvalid();
    return token;
  }

  Future<void> _loadOrders() async {
    final token = await _token();
    if (token == null) return;
    setState(() => _loading = true);
    final result = await Api.orders(token);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.message == tokenMissingMessage) {
      _tokenInvalid();
      return;
    }
    if (!result.success) {
      _show(result.message.isEmpty ? 'Gagal memuat pembayaran.' : result.message, false);
      return;
    }
    setState(() {
      _orders = (result.data as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromJson)
          .toList();
    });
  }

  Future<void> _openOrder(OrderSummary order) async {
    final token = await _token();
    if (token == null) return;
    setState(() => _busyOrderId = order.id);
    final result = await Api.orderDetail(token, order.id);
    if (!mounted) return;
    setState(() => _busyOrderId = null);
    if (result.message == tokenMissingMessage) {
      _tokenInvalid();
      return;
    }
    if (!result.success) {
      _show(result.message.isEmpty ? 'Gagal memuat detail pembayaran.' : result.message, false);
      return;
    }
    if (result.data is! Map<String, dynamic>) {
      _show('Data detail pembayaran tidak valid.', false);
      return;
    }
    final detail = OrderDetail.fromJson(result.data as Map<String, dynamic>);
    await showSnapPaymentDialog(
      context: context,
      payment: detail.checkoutData,
      itemContent: OrderItemsPreview(items: detail.items),
      showMessage: widget.showMessage,
    );
    if (mounted) await _loadOrders();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PEMBAYARAN',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilih order untuk melihat detail dan melanjutkan pembayaran.',
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
              if (_orders.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada pembayaran.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 17),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 110),
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return OrderCard(
                    order: order,
                    busy: _busyOrderId == order.id,
                    onTap: () => _openOrder(order),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.busy,
    required this.onTap,
  });

  final OrderSummary order;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.cyan,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.receipt_long_outlined, color: AppColors.cyan),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${shortId(order.id)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.itemSummary.isEmpty ? 'Order' : order.itemSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusBadge(status: order.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formatDateTime(order.transactionDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatRupiah(order.grandTotal),
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final paid = status.toLowerCase() == 'paid' || status.toLowerCase() == 'settlement';
    final color = paid ? AppColors.success : AppColors.yellow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class OrderItemsPreview extends StatelessWidget {
  const OrderItemsPreview({super.key, required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.stroke, height: 26),
        const Text(
          'Detail item',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: AppColors.input,
                    child: item.image == null
                        ? const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 20)
                        : Image.network(
                            '$apiBase${item.image}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${item.quantity} x ${formatRupiah(item.price)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(item.subtotal),
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String shortId(String value) => value.length <= 8 ? value : value.substring(0, 8).toUpperCase();

String formatDateTime(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
