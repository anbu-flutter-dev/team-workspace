import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/router/app_routes.dart';

/// Routes are added feature-by-feature as each is built; auth-aware
/// redirect logic is wired in once AuthBloc lands.
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _BootstrapPlaceholder(),
      ),
    ],
  );
}

class _BootstrapPlaceholder extends StatelessWidget {
  const _BootstrapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
