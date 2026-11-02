import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/settings/presentation/language_screen.dart';
import '../features/booking/domain/models.dart';
import '../features/booking/presentation/address_step_screen.dart';
import '../features/booking/presentation/confirm_step_screen.dart';
import '../features/booking/presentation/awaiting_payment_screen.dart';
import '../features/booking/presentation/payment_step_screen.dart';
import '../features/booking/presentation/schedule_step_screen.dart';
import '../features/history/presentation/history_screens.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screens.dart';
import '../features/providers/presentation/account_suspended_screen.dart';
import '../features/providers/presentation/provider_profile_screen.dart';
import '../features/providers/presentation/provider_queue_screen.dart';
import '../features/providers/presentation/review_application_screen.dart';
import '../features/providers/presentation/service_region_screen.dart';
import '../features/tracking/presentation/tracking_screen.dart';
import 'widgets/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

Widget _shell(String location, Widget child) {
  return MainShell(location: location, child: child);
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authProvider, (_, __) => refresh.value++);
  ref.listen(splashReadyProvider, (_, __) => refresh.value++);
  ref.listen(languageChosenProvider, (_, __) => refresh.value++);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final splashReady = ref.read(splashReadyProvider);
      final auth = ref.read(authProvider);
      final location = state.uri.path;
      final onSplash = location == '/splash';
      final onAuth =
          location == '/login' || location == '/forgot-password';
      final onLanguage = location == '/language';
      final languageChosen = ref.read(languageChosenProvider);

      if (!splashReady) {
        return onSplash ? null : '/splash';
      }
      if (auth is AuthUnknown) {
        return onSplash ? null : '/splash';
      }
      if (!languageChosen && !onLanguage) {
        return '/language';
      }
      if (auth is AuthUnauthenticated || auth is AuthError) {
        return onAuth || onLanguage ? null : '/login';
      }
      if (auth is AuthAuthenticated && (onAuth || onSplash)) {
        return '/home';
      }
      if (auth is AuthLoading && onAuth) return null;
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => LanguageScreen(
          fromSettings: state.uri.queryParameters['from'] == 'settings',
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final extra = state.extra;
          return ForgotPasswordScreen(
            initialPhone: extra is String ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => _shell(state.uri.path, const HomeScreen()),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => _shell(state.uri.path, const HistoryScreen()),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => _shell(
              state.uri.path,
              BookingDetailScreen(bookingId: state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: 'invoice',
                builder: (context, state) => InvoiceScreen(
                  bookingId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => _shell(state.uri.path, const ProfileScreen()),
        routes: [
          GoRoute(
            path: 'addresses',
            builder: (context, state) =>
                _shell(state.uri.path, const AddressListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const AddressFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => AddressFormScreen(
                  addressId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/booking/address',
        builder: (context, state) => const AddressStepScreen(),
      ),
      GoRoute(
        path: '/booking/schedule',
        builder: (context, state) => const ScheduleStepScreen(),
      ),
      GoRoute(
        path: '/booking/confirm',
        builder: (context, state) => const ConfirmStepScreen(),
      ),
      GoRoute(
        path: '/booking/:id/pay',
        builder: (context, state) {
          final extra = state.extra;
          return PaymentStepScreen(
            bookingId: state.pathParameters['id']!,
            booking: extra is Booking ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/booking/:id/settle',
        builder: (context, state) {
          final extra = state.extra;
          return AwaitingPaymentScreen(
            bookingId: state.pathParameters['id']!,
            booking: extra is Booking ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (context, state) => TrackingScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/providers',
        builder: (context, state) => const ProviderQueueScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => ReviewApplicationScreen(
              providerId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (context, state) => ProviderProfileScreen(
                  providerId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/account/suspended',
        builder: (context, state) => const AccountSuspendedScreen(),
      ),
      GoRoute(
        path: '/onboarding/region',
        builder: (context, state) => const ServiceRegionScreen(),
      ),
    ],
  );
});

void syncRouterToAuth(GoRouter router, AuthState previous, AuthState next) {
  String path = '';
  try {
    path = router.routerDelegate.currentConfiguration.uri.path;
  } catch (_) {}

  if (next is AuthAuthenticated && previous is! AuthAuthenticated) {
    if (path == '/login' ||
        path == '/forgot-password' ||
        path == '/splash' ||
        path == '/language' ||
        path.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (router.routerDelegate.currentConfiguration.uri.path != '/home') {
            router.go('/home');
          }
        } catch (_) {
          router.go('/home');
        }
      });
    }
    return;
  }

  if ((next is AuthUnauthenticated || next is AuthError) &&
      previous is AuthAuthenticated) {
    if (path != '/login' &&
        path != '/forgot-password' &&
        path != '/language') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go('/login');
      });
    }
  }
}
