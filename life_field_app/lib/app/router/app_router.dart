import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/shared/presentation/admin_home_screen.dart';
import '../../features/shared/presentation/client_home_screen.dart';
import '../../features/shared/presentation/meal_detail_screen.dart';
import '../../features/shared/presentation/pro_home_screen.dart';
import 'go_router_refresh_stream.dart';
import 'role_redirect.dart';
import 'route_paths.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider.notifier);
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == RoutePaths.login;
      final isAuthenticated = authState.isAuthenticated;
      if (!isAuthenticated) {
        return loggingIn ? null : RoutePaths.login;
      }

      final user = authState.user;
      if (user == null) {
        return RoutePaths.login;
      }

      final homePath = roleToHomeRoute(user.role);
      if (loggingIn || state.matchedLocation == '/') {
        return homePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.clientHome,
        builder: (context, state) => const ClientHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.proHome,
        builder: (context, state) => const ProHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        name: RoutePaths.mealDetailName,
        path: RoutePaths.mealDetail,
        builder: (context, state) {
          final indexParam = state.pathParameters['mealIndex'];
          final mealIndex = int.tryParse(indexParam ?? '') ?? 1;
          final extra = state.extra;
          final args = extra is MealDetailArgs ? extra : null;
          return MealDetailScreen(
            mealIndex: args?.mealIndex ?? mealIndex,
            initialFoods: args?.foods ?? const [],
          );
        },
      ),
    ],
  );
});
