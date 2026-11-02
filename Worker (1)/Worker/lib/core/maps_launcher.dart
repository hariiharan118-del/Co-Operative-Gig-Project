import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the native maps app for turn-by-turn navigation.
Future<bool> openNativeNavigation({
  required double lat,
  required double lng,
}) async {
  if (kIsWeb) {
    return launchUrl(
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    final googleNav = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(googleNav)) {
      return launchUrl(googleNav, mode: LaunchMode.externalApplication);
    }
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final apple = Uri.parse('maps://?daddr=$lat,$lng&dirflg=d');
    if (await canLaunchUrl(apple)) {
      return launchUrl(apple, mode: LaunchMode.externalApplication);
    }
  }

  return launchUrl(
    Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    ),
    mode: LaunchMode.externalApplication,
  );
}

Future<bool> openPhoneDialer(String phone) {
  final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (sanitized.isEmpty) return Future.value(false);
  return launchUrl(
    Uri.parse('tel:$sanitized'),
    mode: LaunchMode.externalApplication,
  );
}
