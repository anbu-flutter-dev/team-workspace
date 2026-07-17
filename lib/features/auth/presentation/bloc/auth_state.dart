import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/auth/domain/entities/app_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Session not yet resolved — splash screen shows while this is current.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

/// Sign-in/sign-up submission in flight — drives the button spinner.
final class AuthSubmissionInProgress extends AuthState {
  const AuthSubmissionInProgress();
}

/// One-shot: the bloc drops back to AuthUnauthenticated right after this,
/// listener widgets should react via listenWhen rather than treat it as a resting state.
final class AuthSubmissionFailure extends AuthState {
  const AuthSubmissionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
