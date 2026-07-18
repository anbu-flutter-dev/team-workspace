import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_save_outcome.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';

class CreateTaskUseCase {
  CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Result<TaskSaveOutcome>> call({
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
  }) {
    return _repository.createTask(
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
    );
  }
}
