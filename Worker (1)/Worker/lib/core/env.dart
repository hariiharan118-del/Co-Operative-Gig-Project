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

  static String get msg91AuthKey {
    const fromDefine = String.fromEnvironment('MSG91_AUTH_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet('MSG91_AUTH_KEY') ?? '';
  }

  static String get msg91WidgetId {
    const fromDefine = String.fromEnvironment('MSG91_WIDGET_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet('MSG91_WIDGET_ID') ?? '';
  }

  static String get msg91WidgetAuthToken {
    const fromDefine = String.fromEnvironment('MSG91_WIDGET_AUTH_TOKEN');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet('MSG91_WIDGET_AUTH_TOKEN') ?? '';
  }

  static String get msg91TemplateId {
    const fromDefine = String.fromEnvironment('MSG91_TEMPLATE_ID');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet('MSG91_TEMPLATE_ID') ?? '';
  }

  static String get msg91Sender {
    const fromDefine = String.fromEnvironment('MSG91_SENDER');
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet('MSG91_SENDER') ?? 'OTPSMS';
  }
}
