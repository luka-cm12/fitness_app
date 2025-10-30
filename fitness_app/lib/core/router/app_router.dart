import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/user_type_selection_page.dart';
import '../../features/auth/presentation/pages/athlete_register_page.dart';
import '../../features/auth/presentation/pages/professional_register_page.dart';
import '../../features/auth/presentation/pages/modern_login_page.dart';
import '../../features/auth/presentation/pages/professional_pending_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/workouts/presentation/pages/workouts_page.dart';
import '../../features/nutrition/presentation/pages/nutrition_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = user != null;

      final isAuthRoute = state.uri.toString().startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const ModernLoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/auth/user-type-selection',
        name: 'user-type-selection',
        builder: (context, state) => const UserTypeSelectionPage(),
      ),
      GoRoute(
        path: '/auth/register/athlete',
        name: 'athlete-register',
        builder: (context, state) => const AthleteRegisterPage(),
      ),
      GoRoute(
        path: '/auth/register/professional',
        name: 'professional-register',
        builder: (context, state) => const ProfessionalRegisterPage(),
      ),
      GoRoute(
        path: '/auth/professional-pending',
        name: 'professional-pending',
        builder: (context, state) => const ProfessionalPendingPage(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/auth/reset-password/:token',
        name: 'reset-password',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordPage(token: token);
        },
      ),

      // Main App Routes
      GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/workouts',
        name: 'workouts',
        builder: (context, state) => const WorkoutsPage(),
      ),
      GoRoute(
        path: '/nutrition',
        name: 'nutrition',
        builder: (context, state) => const NutritionPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
});
