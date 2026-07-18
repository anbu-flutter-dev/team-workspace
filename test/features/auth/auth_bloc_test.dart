import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/analytics/analytics_service.dart';
import 'package:team_workspace/core/error/failure.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/auth/domain/entities/app_user.dart';
import 'package:team_workspace/features/auth/domain/repositories/auth_repository.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

const _user = AppUser(id: '1', email: 'user@example.com');

void main() {
  late MockAuthRepository repository;
  late MockSignInUseCase signIn;
  late MockSignUpUseCase signUp;
  late MockSignOutUseCase signOut;
  late MockAnalyticsService analytics;

  setUp(() {
    repository = MockAuthRepository();
    signIn = MockSignInUseCase();
    signUp = MockSignUpUseCase();
    signOut = MockSignOutUseCase();
    analytics = MockAnalyticsService();
    when(
      () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
    ).thenReturn(null);
  });

  AuthBloc buildBloc() =>
      AuthBloc(repository, signIn, signUp, signOut, analytics);

  group('AuthSignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'logs the sign_out analytics event and stays wherever the stream '
      'subscription leaves it when signOut succeeds',
      setUp: () {
        when(() => signOut()).thenAnswer((_) async => const Ok(null));
      },
      build: buildBloc,
      seed: () => const AuthAuthenticated(_user),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => <AuthState>[],
      verify: (_) {
        verify(() => analytics.logEvent('sign_out')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthSubmissionFailure then reverts to the pre-signout state '
      'when signOut fails, and does not log sign_out',
      setUp: () {
        when(
          () => signOut(),
        ).thenAnswer((_) async => const Err(AuthFailure('Network error')));
      },
      build: buildBloc,
      seed: () => const AuthAuthenticated(_user),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        const AuthSubmissionFailure('Network error'),
        const AuthAuthenticated(_user),
      ],
      verify: (_) {
        verifyNever(() => analytics.logEvent('sign_out'));
      },
    );
  });
}
