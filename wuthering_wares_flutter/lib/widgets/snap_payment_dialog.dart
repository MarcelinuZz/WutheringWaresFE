import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../utils/native_bridge.dart';
import 'action_buttons.dart';

Future<void> showSnapPaymentDialog({
  required BuildContext context,
  required CheckoutData payment,
  String? message,
  Widget? itemContent,
  required void Function(String message, {required bool success}) showMessage,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => SnapPaymentDialog(
      payment: payment,
      message: message,
      itemContent: itemContent,
      showMessage: showMessage,
    ),
  );
}

class SnapPaymentDialog extends StatefulWidget {
  const SnapPaymentDialog({
    super.key,
    required this.payment,
    required this.showMessage,
    this.message,
    this.itemContent,
  });

  final CheckoutData payment;
  final String? message;
  final Widget? itemContent;
  final void Function(String message, {required bool success}) showMessage;

  @override
  State<SnapPaymentDialog> createState() => _SnapPaymentDialogState();
}

class _SnapPaymentDialogState extends State<SnapPaymentDialog> {
  bool _opening = false;

  Future<void> _openSnap() async {
    if (widget.payment.snapRedirectUrl.isEmpty) {
      widget.showMessage('Link pembayaran tidak tersedia.', success: false);
      return;
    }
    setState(() => _opening = true);
    final opened = await NativeBridge.openUrl(widget.payment.snapRedirectUrl);
    if (!mounted) return;
    setState(() => _opening = false);
    if (opened != true) {
      widget.showMessage('Tidak dapat membuka halaman pembayaran.', success: false);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.payments_outlined, color: AppColors.cyan),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pembayaran Midtrans',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (widget.message != null && widget.message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.message!,
                  style: const TextStyle(color: AppColors.success, height: 1.4),
                ),
              ],
              const SizedBox(height: 18),
              PaymentInfoRow(label: 'ID Transaksi', value: widget.payment.transactionId),
              PaymentInfoRow(label: 'Order Midtrans', value: widget.payment.midtransOrderId),
              PaymentInfoRow(label: 'Status', value: widget.payment.status),
              const Divider(color: AppColors.stroke, height: 26),
              PaymentInfoRow(label: 'Harga sebelum pajak', value: formatRupiah(widget.payment.totalPrice)),
              PaymentInfoRow(label: 'Pajak 5%', value: formatRupiah(widget.payment.tax)),
              PaymentInfoRow(
                label: 'Harga setelah pajak',
                value: formatRupiah(widget.payment.grandTotal),
                highlight: true,
              ),
              if (widget.itemContent != null) ...[
                const SizedBox(height: 12),
                widget.itemContent!,
              ],
              const SizedBox(height: 18),
              PrimaryActionButton(
                text: _opening ? 'MEMBUKA...' : 'BAYAR SEKARANG',
                loading: _opening,
                onPressed: _openSnap,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup, bayar nanti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentInfoRow extends StatelessWidget {
  const PaymentInfoRow({
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
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: highlight ? AppColors.cyan : AppColors.textPrimary,
              fontSize: highlight ? 17 : 14,
              fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
