import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/core/router/app_router.dart';
import 'package:team_workspace/core/theme/app_theme.dart';
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
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthSubscriptionRequested()),
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Team Workspace',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            routerConfig: buildAppRouter(context.read<AuthBloc>()),
          );
        },
      ),
    );
  }
}
