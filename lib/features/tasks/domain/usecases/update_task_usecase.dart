import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_save_outcome.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';

class UpdateTaskUseCase {
  UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Result<TaskSaveOutcome>> call(Task task) =>
      _repository.updateTask(task);
}
