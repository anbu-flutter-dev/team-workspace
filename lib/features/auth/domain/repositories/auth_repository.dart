import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/auth/domain/entities/app_user.dart';

/// Contract for authentication — the presentation layer never touches Firebase directly.
abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}
