import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/env.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/data/mock_bookings.dart';
import '../data/razorpay_checkout.dart';
import '../domain/models.dart';
import '../providers/booking_providers.dart';
import 'payment_receipt_card.dart';

class PaymentStepScreen extends ConsumerStatefulWidget {
  const PaymentStepScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  final String bookingId;
  final Booking? booking;

  @override
  ConsumerState<PaymentStepScreen> createState() => _PaymentStepScreenState();
}

class _PaymentStepScreenState extends ConsumerState<PaymentStepScreen> {
  Booking? _booking;
  PaymentOrder? _order;
  PaymentReceipt? _receipt;
  RazorpayCheckoutResult? _pendingVerify;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  bool get _paid =>
      _receipt?.isPaid == true || _order?.alreadyPaid == true;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final booking = _booking ?? await repo.get(widget.bookingId);
      final order = await repo.createPaymentOrder(widget.bookingId);
      PaymentReceipt? receipt = order.receipt;
      if (order.alreadyPaid) {
        try {
          receipt = await repo.getPayment(widget.bookingId);
        } catch (_) {
          receipt ??= order.receipt;
        }
      }
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _order = order;
        _receipt = receipt;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pay() async {
    if (_paid) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(bookingsRepositoryProvider);
      final pending = _pendingVerify;
      PaymentReceipt receipt;

      if (pending != null &&
          pending.paymentId.isNotEmpty &&
          pending.signature.isNotEmpty) {
        receipt = await repo.verifyPayment(
          bookingId: widget.bookingId,
          razorpayOrderId: pending.orderId,
          razorpayPaymentId: pending.paymentId,
          razorpaySignature: pending.signature,
        );
      } else {
        var order = _order;
        if (order == null || order.orderId.isEmpty) {
          order = await repo.createPaymentOrder(widget.bookingId);
          if (!mounted) return;
          _order = order;
          if (order.alreadyPaid) {
            receipt = order.receipt ?? await repo.getPayment(widget.bookingId);
            _finishPaid(receipt);
            return;
          }
        }

        final keyId = order.keyId.isNotEmpty ? order.keyId : Env.razorpayKeyId;
        if (keyId.isEmpty || order.orderId.isEmpty) {
          throw StateError('booking.payFailed'.tr());
        }

        final auth = ref.read(authProvider);
        final user = auth is AuthAuthenticated ? auth.session.user : null;
        final checkout = await openRazorpayCheckout(
          keyId: keyId,
          orderId: order.orderId,
          amountPaise: order.amountPaise > 0
              ? order.amountPaise
              : (_booking?.totalPaise ?? 0),
          description: _booking?.categoryName ?? 'KRIYANTA booking',
          contact: user?.phone,
          email: user?.email,
        );
        if (checkout.paymentId.isEmpty || checkout.signature.isEmpty) {
          throw StateError('booking.payFailed'.tr());
        }
        _pendingVerify = checkout;
        receipt = await repo.verifyPayment(
          bookingId: widget.bookingId,
          razorpayOrderId:
              checkout.orderId.isEmpty ? order.orderId : checkout.orderId,
          razorpayPaymentId: checkout.paymentId,
          razorpaySignature: checkout.signature,
        );
      }

      try {
        receipt = await repo.getPayment(widget.bookingId);
      } catch (_) {}

      if (!mounted) return;
      _finishPaid(receipt);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _busy = false;
      });
    }
  }

  void _finishPaid(PaymentReceipt receipt) {
    final order = _order;
    _pendingVerify = null;
    setState(() {
      _receipt = receipt;
      if (order != null) {
        _order = PaymentOrder(
          orderId: order.orderId,
          keyId: order.keyId,
          amountPaise: order.amountPaise,
          currency: order.currency,
          alreadyPaid: true,
          receipt: receipt,
        );
      }
      _busy = false;
    });
  }

  void _retry() {
    if (_order == null && _pendingVerify == null) {
      _prepare();
      return;
    }
    _pay();
  }

  void _continue() {
    context.go('/tracking/${widget.bookingId}');
  }

  @override
  Widget build(BuildContext context) {
    final amount = _order?.amountPaise ?? _booking?.totalPaise ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('booking.payTitle'.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_paid && _receipt != null) ...[
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'booking.paySuccess'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  PaymentReceiptCard(
                    receipt: _receipt!,
                    fallbackCategory: _booking?.categoryName,
                    fallbackAmountPaise: amount,
                  ),
                ] else ...[
                  Text(
                    _booking?.categoryName ?? 'booking.category'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatPaise(amount),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kIsWeb ? 'booking.payWeb'.tr() : 'booking.payHint'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      color: AppColors.errorSoft,
                      borderColor: AppColors.error,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'booking.payFailed'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_error!),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _paid
              ? PressScale(
                  child: FilledButton(
                    onPressed: _continue,
                    child: Text('booking.payContinue'.tr()),
                  ),
                )
              : PressScale(
                  enabled: !_busy && !_loading,
                  child: FilledButton(
                    onPressed: _busy || _loading ? null : _retry,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _error != null
                                ? 'booking.payRetry'.tr()
                                : 'booking.payCta'.tr(
                                    args: [formatPaise(amount)],
                                  ),
                          ),
                  ),
                ),
        ),
      ),
    );
  }
}
