import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignOutUseCase {
  SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
