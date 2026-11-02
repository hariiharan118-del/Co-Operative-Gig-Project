import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves runtime config from `--dart-define` first, then `.env`.
class Env {
  Env._();

  static String get apiBaseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet('API_BASE_URL') ?? 'http://localhost:3000';
  }

  static String get googleMapsApiKey {
    const fromDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet('GOOGLE_MAPS_API_KEY') ?? '';
  }

  static String get razorpayKeyId {
    const fromDefine = String.fromEnvironment('RAZORPAY_KEY_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet('RAZORPAY_KEY_ID') ?? '';
  }
}
