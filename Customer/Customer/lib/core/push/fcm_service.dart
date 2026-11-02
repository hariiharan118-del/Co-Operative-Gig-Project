import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Requests notification permission on first launch and logs the FCM token.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      debugPrint('FCM skipped on web (Firebase options are not configured).');
      return;
    }

    try {
      await Firebase.initializeApp();
    } catch (error, stack) {
      debugPrint(
        'FCM skipped: Firebase is not configured yet '
        '(add google-services.json / GoogleService-Info.plist). $error',
      );
      debugPrint('$stack');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      final token = await messaging.getToken();
      debugPrint('FCM token: $token');

      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM token refreshed: $newToken');
        // TODO: POST /users/me/devices  body: { "fcmToken": newToken, "platform": "android"|"ios" }
      });

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('FCM foreground message: ${message.messageId} ${message.data}');
      });
    } catch (error, stack) {
      debugPrint('FCM setup skipped non-fatally: $error');
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}
