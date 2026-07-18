import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/analytics/analytics_route_observer.dart';
import 'package:team_workspace/core/analytics/analytics_service.dart';
import 'package:team_workspace/core/router/app_routes.dart';
import 'package:team_workspace/core/router/go_router_refresh_stream.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/auth/presentation/pages/login_page.dart';
import 'package:team_workspace/features/auth/presentation/pages/sign_up_page.dart';
import 'package:team_workspace/features/auth/presentation/pages/splash_page.dart';
import 'package:team_workspace/features/tasks/presentation/pages/create_task_page.dart';
import 'package:team_workspace/features/tasks/presentation/pages/dashboard_page.dart';
import 'package:team_workspace/features/tasks/presentation/pages/edit_task_page.dart';
import 'package:team_workspace/features/tasks/presentation/pages/task_detail_page.dart';

GoRouter buildAppRouter(AuthBloc authBloc, AnalyticsService analytics) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    observers: [AnalyticsRouteObserver(analytics)],
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signUp;

      if (authState is AuthInitial) return null;
      if (authState is AuthUnauthenticated) {
        return isAuthRoute ? null : AppRoutes.login;
      }
      if (authState is AuthAuthenticated) {
        final onSplashOrAuthRoute =
            state.matchedLocation == AppRoutes.splash || isAuthRoute;
        return onSplashOrAuthRoute ? AppRoutes.dashboard : null;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'sign_up',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.createTask,
        name: 'create_task',
        builder: (context, state) => const CreateTaskPage(),
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        name: 'task_detail',
        builder: (context, state) =>
            TaskDetailPage(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: AppRoutes.editTask,
        name: 'edit_task',
        builder: (context, state) =>
            EditTaskPage(taskId: state.pathParameters['taskId']!),
      ),
    ],
  );
}
