import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentOrder {
  const PaymentOrder({
    required this.orderId,
    required this.keyId,
    required this.amount,
    this.currency = 'INR',
    this.contact,
    this.description,
    this.name = 'KRIYANTA Partner',
    this.alreadyPaid = false,
  });

  final String orderId;
  final String keyId;
  final int amount;
  final String currency;
  final String? contact;
  final String? description;
  final String name;
  final bool alreadyPaid;

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    final paise = json['amountPaise'] ?? json['amount'];
    return PaymentOrder(
      orderId: '${json['orderId'] ?? ''}',
      keyId: '${json['keyId'] ?? ''}',
      amount: paise is int ? paise : int.tryParse('$paise') ?? 0,
      currency: '${json['currency'] ?? 'INR'}',
      contact: json['contact'] as String?,
      description: json['description'] as String?,
      name: '${json['name'] ?? 'KRIYANTA Partner'}',
      alreadyPaid: json['alreadyPaid'] == true,
    );
  }
}

Future<PaymentSuccessResponse> openRazorpayCheckout(PaymentOrder order) {
  if (kIsWeb) {
    return Future.error(
      StateError('Razorpay checkout needs the Android or iOS app, not web.'),
    );
  }
  if (order.orderId.isEmpty || order.keyId.isEmpty) {
    return Future.error(StateError('Payment order is missing key or order id'));
  }

  final razorpay = Razorpay();
  final done = Completer<PaymentSuccessResponse>();

  void finish() {
    razorpay.clear();
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
    if (!done.isCompleted) done.complete(response);
    finish();
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    if (!done.isCompleted) {
      done.completeError(
        StateError(response.message ?? 'Payment cancelled or failed'),
      );
    }
    finish();
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

  razorpay.open({
    'key': order.keyId,
    'amount': order.amount,
    'currency': order.currency,
    'name': order.name,
    'description': order.description ?? 'Job payment',
    'order_id': order.orderId,
    'prefill': {if (order.contact != null) 'contact': order.contact},
    'theme': {'color': '#0F766E'},
  });

  return done.future;
}
