import 'dart:async';
import 'dart:io';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../domain/models.dart';

Future<RazorpayCheckoutResult> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  String currency = 'INR',
  String name = 'KRIYANTA',
  String? description,
  String? contact,
  String? email,
}) {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    return Future.error(
      UnsupportedError(
        'Razorpay checkout needs the Android or iOS app, not this platform.',
      ),
    );
  }
  if (keyId.isEmpty || orderId.isEmpty) {
    return Future.error(StateError('Payment order is missing key or order id'));
  }

  final razorpay = Razorpay();
  final done = Completer<RazorpayCheckoutResult>();

  void finish() {
    razorpay.clear();
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
    if (!done.isCompleted) {
      done.complete(
        RazorpayCheckoutResult(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId ?? orderId,
          signature: response.signature ?? '',
        ),
      );
    }
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
    'key': keyId,
    'amount': amountPaise,
    'currency': currency,
    'name': name,
    'description': description ?? 'Booking payment',
    'order_id': orderId,
    'prefill': {
      if (contact != null && contact.isNotEmpty) 'contact': contact,
      if (email != null && email.isNotEmpty) 'email': email,
    },
    'theme': {'color': '#17707D'},
  });

  return done.future;
}
