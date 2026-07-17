import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_workspace/core/error/failure.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:team_workspace/features/auth/data/firebase_auth_error_mapper.dart';
import 'package:team_workspace/features/auth/data/models/app_user_mapper.dart';
import 'package:team_workspace/features/auth/domain/entities/app_user.dart';
import 'package:team_workspace/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> get authStateChanges =>
      _remoteDataSource.authStateChanges.map((user) => user?.toEntity());

  @override
  AppUser? get currentUser => _remoteDataSource.currentUser?.toEntity();

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Ok(user.toEntity());
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(mapFirebaseAuthErrorCode(e.code)));
    }
  }

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signUp(
        email: email,
        password: password,
      );
      return Ok(user.toEntity());
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(mapFirebaseAuthErrorCode(e.code)));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Ok(null);
    } on FirebaseAuthException catch (e) {
      return Err(AuthFailure(mapFirebaseAuthErrorCode(e.code)));
    }
  }
}
