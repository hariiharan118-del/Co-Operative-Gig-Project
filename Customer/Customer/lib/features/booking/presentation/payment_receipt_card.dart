import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../history/data/mock_bookings.dart';
import '../domain/models.dart';

class PaymentReceiptCard extends StatelessWidget {
  const PaymentReceiptCard({
    super.key,
    required this.receipt,
    this.fallbackCategory,
    this.fallbackAmountPaise,
  });

  final PaymentReceipt receipt;
  final String? fallbackCategory;
  final int? fallbackAmountPaise;

  @override
  Widget build(BuildContext context) {
    final category = receipt.categoryName?.trim().isNotEmpty == true
        ? receipt.categoryName!
        : (fallbackCategory ?? '');
    final amount = receipt.amountPaise > 0
        ? receipt.amountPaise
        : (fallbackAmountPaise ?? 0);
    final paidAt = receipt.paidAt;
    final paymentId = receipt.razorpayPaymentId;
    final orderId = receipt.razorpayOrderId;
    final invoiceUrl = receipt.invoiceUrl;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'booking.receiptNo'.tr()} ${receipt.receiptNo}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(category, style: const TextStyle(color: AppColors.muted)),
          ],
          const Divider(height: 32),
          _ReceiptRow(label: 'history.status'.tr(), value: receipt.status),
          _ReceiptRow(
            label: 'history.total'.tr(),
            value: formatPaise(amount),
            emphasize: true,
          ),
          if (paymentId != null && paymentId.isNotEmpty)
            _ReceiptRow(label: 'booking.receiptPaymentId'.tr(), value: paymentId),
          if (orderId != null && orderId.isNotEmpty)
            _ReceiptRow(label: 'booking.receiptOrderId'.tr(), value: orderId),
          if (paidAt != null)
            _ReceiptRow(
              label: 'booking.receiptPaidAt'.tr(),
              value: DateFormat('d MMM y, h:mm a').format(paidAt.toLocal()),
            ),
          if (invoiceUrl != null && invoiceUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                final uri = Uri.tryParse(invoiceUrl);
                if (uri == null) return;
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text('history.invoice'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
