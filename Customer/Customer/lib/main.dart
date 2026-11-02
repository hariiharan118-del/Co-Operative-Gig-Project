import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale/app_languages.dart';
import 'core/locale/language_prefs.dart';
import 'core/push/fcm_service.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguagePrefs.init();
  await EasyLocalization.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {
      // API_BASE_URL can still be provided via --dart-define=API_BASE_URL=...
    }
  }

  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (error) {
      debugPrint('FCM background handler not registered: $error');
    }

    try {
      await FcmService.instance.initialize();
    } catch (error) {
      debugPrint('FCM initialization skipped: $error');
    }
  }

  runApp(
    EasyLocalization(
      supportedLocales: AppLanguages.locales,
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: LanguagePrefs.hasChosen ? LanguagePrefs.locale : const Locale('en'),
      useOnlyLangCode: true,
      saveLocale: true,
      child: const ProviderScope(child: CoopGigApp()),
    ),
  );
}

class CoopGigApp extends ConsumerWidget {
  const CoopGigApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.listen<AuthState>(authProvider, (previous, next) {
      syncRouterToAuth(router, previous ?? const AuthUnknown(), next);
    });
    return MaterialApp.router(
      key: ValueKey(context.locale.toLanguageTag()),
      title: 'KRIYANTA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
