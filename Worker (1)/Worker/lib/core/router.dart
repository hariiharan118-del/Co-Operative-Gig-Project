import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/settings/presentation/language_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/earnings/presentation/earnings_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/job/presentation/active_job_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/verification/domain/verification_state.dart';
import '../features/verification/presentation/verification_gate_screen.dart';
import '../features/verification/providers/verification_provider.dart';
import '../features/welfare/presentation/welfare_screens.dart';
import 'widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authProvider, (_, __) {
    refresh.value++;
  });
  ref.listen<VerificationState>(verificationProvider, (_, __) {
    refresh.value++;
  });
  ref.listen<bool>(splashReadyProvider, (_, __) {
    refresh.value++;
  });
  ref.listen<bool>(languageChosenProvider, (_, __) {
    refresh.value++;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final verification = ref.read(verificationProvider);
      final location = state.matchedLocation;
      final onSplash = location == '/splash';
      final onAuth = location == '/login' || location == '/forgot-password';
      final onLanguage = location == '/language';
      final onVerification = location == '/verification';
      final languageChosen = ref.read(languageChosenProvider);

      final splashReady = ref.read(splashReadyProvider);
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
      if (auth is AuthAuthenticated) {
        if (!verification.isResolved) {
          return onSplash ? null : '/splash';
        }
        if (verification.isBlocked) {
          return onVerification ? null : '/verification';
        }
        if (onAuth || onSplash || onVerification) {
          return '/dashboard';
        }
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
          final digits = extra is String
              ? extra.replaceAll(RegExp(r'\D'), '')
              : '';
          return ForgotPasswordScreen(
            initialPhone: digits.length == 10 ? digits : '',
          );
        },
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationGateScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/earnings',
                builder: (context, state) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'welfare',
                    builder: (context, state) => const WelfareScreen(),
                    routes: [
                      GoRoute(
                        path: 'claim',
                        builder: (context, state) => const FileClaimScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/job/:id',
        builder: (context, state) => ActiveJobScreen(
          jobId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/welfare',
        builder: (context, state) => const WelfareScreen(),
        routes: [
          GoRoute(
            path: 'claim',
            builder: (context, state) => const FileClaimScreen(),
          ),
        ],
      ),
    ],
  );
});
