import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/error/exceptions.dart';
import 'package:team_workspace/core/error/failure.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/core/network/api_constants.dart';
import 'package:team_workspace/core/utils/log.dart';
import 'package:team_workspace/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/tasks/data/local/task_local_datasource.dart';
import 'package:team_workspace/features/tasks/data/models/task_dto_mapper.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_page.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/tasks/domain/task_enrichment.dart';

@LazySingleton(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remote, this._local);

  final TaskRemoteDataSource _remote;
  final TaskLocalDataSource _local;

  final StreamController<Task> _taskUpdatesController =
      StreamController.broadcast();

  @override
  Stream<Task> get taskUpdates => _taskUpdatesController.stream;

  @override
  Future<Result<TaskPage>> getTasks({required int page}) async {
    try {
      final response = await _remote.fetchTasks(page: page);
      final overlay = _local.readOverlay();
      final apiTasks = response.todos
          .map((dto) => overlay[dto.id.toString()] ?? dto.toEntity())
          .toList();

      var tasks = apiTasks;
      if (page == 1) {
        final localOnly = overlay.values.where((t) => t.isLocalOnly).toList()
          ..sort((a, b) => b.id.compareTo(a.id));
        tasks = [...localOnly, ...apiTasks];
        unawaited(_local.writeCachedTasks(tasks));
      }

      final hasMore = response.todos.length == ApiConstants.pageSize;
      return Ok(TaskPage(tasks: tasks, hasMore: hasMore, isFromCache: false));
    } on NetworkException {
      if (page == 1) {
        final cached = _local.readCachedTasks();
        if (cached != null) {
          return Ok(TaskPage(tasks: cached, hasMore: false, isFromCache: true));
        }
      }
      return const Err(NetworkFailure());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<Task>> getTaskById(String id) async {
    final overlayHit = _local.readOverlay()[id];
    if (overlayHit != null) return Ok(overlayHit);

    final numericId = int.tryParse(id);
    if (numericId == null) return const Err(CacheFailure('Task not found.'));

    try {
      final dto = await _remote.fetchTaskById(numericId);
      return Ok(dto.toEntity());
    } on NetworkException {
      return const Err(NetworkFailure());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    }
  }

  @override
  Future<Result<Task>> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
  }) async {
    final id = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final task = Task(
      id: id,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      status: TaskStatus.pending,
      assignedUser: TaskEnrichment.assignedUserFor(id.hashCode),
    );

    try {
      await _local.writeOverlayEntry(task);
    } on Exception {
      return const Err(CacheFailure());
    }

    _taskUpdatesController.add(task);
    unawaited(
      _remote
          .createTask(todo: title, completed: false)
          .catchError((Object e) => log('best-effort create failed', error: e)),
    );
    return Ok(task);
  }

  @override
  Future<Result<Task>> updateTask(Task task) async {
    try {
      await _local.writeOverlayEntry(task);
    } on Exception {
      return const Err(CacheFailure());
    }

    _taskUpdatesController.add(task);

    if (!task.isLocalOnly) {
      unawaited(
        _remote
            .updateTask(
              int.parse(task.id),
              todo: task.title,
              completed: task.isCompleted,
            )
            .catchError(
              (Object e) => log('best-effort update failed', error: e),
            ),
      );
    }
    return Ok(task);
  }

  @override
  Future<void> syncPendingOperations() async {}
}
