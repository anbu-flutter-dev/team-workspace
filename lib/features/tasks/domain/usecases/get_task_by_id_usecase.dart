import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';

class GetTaskByIdUseCase {
  GetTaskByIdUseCase(this._repository);

  final TaskRepository _repository;

  Future<Result<Task>> call(String id) => _repository.getTaskById(id);
}
