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
  return Future.error(
    UnsupportedError(
      'Razorpay checkout needs the Android or iOS app, not this platform.',
    ),
  );
}
