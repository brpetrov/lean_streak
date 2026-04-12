import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../shared/widgets/splash_screen.dart';

// ---------------------------------------------------------------------------
// Route names — use these constants everywhere instead of raw strings
// ---------------------------------------------------------------------------
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const auth = '/auth';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const logMeal = '/log-meal';
  static const history = '/history';
  static const weeklyReview = '/weekly-review';
  static const profile = '/profile';
}

// ---------------------------------------------------------------------------
// A ChangeNotifier that re-notifies GoRouter whenever auth state changes.
// ---------------------------------------------------------------------------
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (previous, next) {
        if (previous?.valueOrNull != next.valueOrNull || previous?.isLoading != next.isLoading) {
          notifyListeners();
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// GoRouter provider
// ---------------------------------------------------------------------------
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      // Additional routes wired in later phases:
      // GoRoute(path: AppRoutes.logMeal, ...),
      // GoRoute(path: AppRoutes.history, ...),
      // GoRoute(path: AppRoutes.weeklyReview, ...),
      // GoRoute(path: AppRoutes.profile, ...),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

// ---------------------------------------------------------------------------
// Redirect logic — called on every navigation + every auth state change
// ---------------------------------------------------------------------------
String? _redirect(Ref ref, GoRouterState state) {
  final authValue = ref.read(authStateProvider);
  final location = state.matchedLocation;

  // While Firebase is still initialising, stay on the splash screen.
  if (authValue.isLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  final isAuthenticated = authValue.valueOrNull != null;

  if (!isAuthenticated) {
    // Send unauthenticated users to /auth (unless already there).
    if (location == AppRoutes.auth) return null;
    return AppRoutes.auth;
  }

  // Authenticated — bounce off auth / splash pages.
  // Onboarding check will be added in Phase 3.
  if (location == AppRoutes.splash || location == AppRoutes.auth) {
    return AppRoutes.dashboard;
  }

  return null; // No redirect needed.
}
