import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_page.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';

/// One page is `limit`/`skip` over dummyjson, merged with the local overlay
/// (created/edited/toggled tasks) so writes reflect immediately and survive restarts.
abstract interface class TaskRepository {
  /// Emits whenever a task is created, edited, or has its status changed —
  /// lets other blocs (dashboard list) react without a refetch.
  Stream<Task> get taskUpdates;

  Future<Result<TaskPage>> getTasks({required int page});

  Future<Result<Task>> getTaskById(String id);

  Future<Result<Task>> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
  });

  Future<Result<Task>> updateTask(Task task);

  /// Replays queued offline writes against the API once connectivity returns.
  Future<void> syncPendingOperations();
}
