import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/analytics/analytics_service.dart';
import 'package:team_workspace/features/auth/domain/repositories/auth_repository.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  // Regression coverage for the AuthBloc DI lifecycle: it's a GetIt lazy
  // singleton meant to live for the whole app, but was previously handed to
  // the widget tree via `BlocProvider(create: (_) => getIt<AuthBloc>())`.
  // BlocProvider's `create:` form takes ownership and calls `.close()` on
  // the bloc when its provider widget is disposed (e.g. a hot reload
  // rebuilding the app root) — which would leave GetIt caching, and handing
  // out, an already-closed singleton to everything else in the app from
  // then on. `BlocProvider.value` doesn't take that ownership, so the
  // singleton should survive the provider widget being torn down.
  testWidgets('AuthBloc survives disposal of the widget that provided it via '
      'BlocProvider.value', (tester) async {
    final bloc = AuthBloc(
      MockAuthRepository(),
      MockSignInUseCase(),
      MockSignUpUseCase(),
      MockSignOutUseCase(),
      MockAnalyticsService(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          // Actually reads the bloc from context — without this, a plain
          // `BlocProvider(create:)` would never even instantiate/register
          // anything to close (it's lazy), which would make this test pass
          // either way and prove nothing.
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // Replaces the whole widget tree, disposing the BlocProvider above —
    // this is what would call `.close()` if it were `BlocProvider(create:)`.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(bloc.isClosed, isFalse);
  });
}
