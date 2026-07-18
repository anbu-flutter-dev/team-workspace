import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/analytics/analytics_service.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/auth/domain/entities/app_user.dart';
import 'package:team_workspace/features/auth/domain/repositories/auth_repository.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:team_workspace/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._authRepository,
    this._signIn,
    this._signUp,
    this._signOut,
    this._analytics,
  ) : super(const AuthInitial()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthSignInSubmitted>(_onSignInSubmitted);
    on<AuthSignUpSubmitted>(_onSignUpSubmitted);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final AnalyticsService _analytics;

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) {
    // Runs for the bloc's lifetime — a separate on<> pipeline per event type
    // means this doesn't block sign-in/sign-up handlers from running.
    return emit.forEach<AppUser?>(
      _authRepository.authStateChanges,
      onData: (user) =>
          user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
    );
  }

  Future<void> _onSignInSubmitted(
    AuthSignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSubmissionInProgress());
    final result = await _signIn(email: event.email, password: event.password);
    result.fold((failure) {
      emit(AuthSubmissionFailure(failure.message));
      emit(const AuthUnauthenticated());
    }, (_) => _analytics.logEvent('sign_in_success'));
  }

  Future<void> _onSignUpSubmitted(
    AuthSignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthSubmissionInProgress());
    final result = await _signUp(email: event.email, password: event.password);
    result.fold((failure) {
      emit(AuthSubmissionFailure(failure.message));
      emit(const AuthUnauthenticated());
    }, (_) => _analytics.logEvent('sign_up_success'));
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Capture the pre-signout state so a failed sign-out can revert to it —
    // the user is still authenticated if this fails, and should stay that
    // way rather than silently ending up on an unauthenticated screen.
    final previous = state;
    final result = await _signOut();
    result.fold((failure) {
      emit(AuthSubmissionFailure(failure.message));
      emit(previous);
    }, (_) => _analytics.logEvent('sign_out'));
  }
}
