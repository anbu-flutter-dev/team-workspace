import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:team_workspace/core/analytics/analytics_service.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/core/router/app_router.dart';
import 'package:team_workspace/core/theme/app_theme.dart';
import 'package:team_workspace/core/theme/theme_cubit.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_event.dart';
import 'package:team_workspace/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureDependencies();
  runApp(const TeamWorkspaceApp());
}

class TeamWorkspaceApp extends StatelessWidget {
  const TeamWorkspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<AuthBloc>()..add(const AuthSubscriptionRequested()),
        ),
        BlocProvider(create: (_) => getIt<ThemeCubit>()),
      ],
      child: Builder(
        builder: (context) {
          // Built once here (not inside the BlocBuilder below) so a theme
          // change never recreates the router and loses navigation state.
          final router = buildAppRouter(
            context.read<AuthBloc>(),
            getIt<AnalyticsService>(),
          );
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp.router(
                title: 'Team Workspace',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                routerConfig: router,
              );
            },
          );
        },
      ),
    );
  }
}
