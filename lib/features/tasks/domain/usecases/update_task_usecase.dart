import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';

@injectable
class UpdateTaskUseCase {
  UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Result<Task>> call(Task task) => _repository.updateTask(task);
}
