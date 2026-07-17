import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/auth/domain/entities/app_user.dart';
import 'package:team_workspace/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignInUseCase {
  SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
