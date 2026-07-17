import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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
  TaskRepositoryImpl(this._remote, this._local, this._connectivity) {
    // Best-effort — if this never fires, queued writes just wait for the
    // next explicit syncPendingOperations() call (e.g. on dashboard refresh).
    // Not stored: this repository is a singleton for the app's lifetime, so
    // there's no meaningful moment to cancel the subscription anyway.
    _connectivity.onConnectivityChanged.listen((results) {
      if (_isConnected(results)) unawaited(syncPendingOperations());
    });
  }

  final TaskRemoteDataSource _remote;
  final TaskLocalDataSource _local;
  final Connectivity _connectivity;

  final StreamController<Task> _taskUpdatesController =
      StreamController.broadcast();

  @override
  Stream<Task> get taskUpdates => _taskUpdatesController.stream;

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<bool> _isOnline() async =>
      _isConnected(await _connectivity.checkConnectivity());

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

    if (await _isOnline()) {
      try {
        await _remote.createTask(todo: title, completed: false);
      } on Exception catch (e) {
        log('create call failed, queuing for retry', error: e);
        await _local.enqueuePendingSync(id);
      }
    } else {
      await _local.enqueuePendingSync(id);
    }
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
      if (await _isOnline()) {
        try {
          await _remote.updateTask(
            int.parse(task.id),
            todo: task.title,
            completed: task.isCompleted,
          );
        } on Exception catch (e) {
          log('update call failed, queuing for retry', error: e);
          await _local.enqueuePendingSync(task.id);
        }
      } else {
        await _local.enqueuePendingSync(task.id);
      }
    }
    return Ok(task);
  }

  @override
  Future<void> syncPendingOperations() async {
    if (!await _isOnline()) return;

    final overlay = _local.readOverlay();
    for (final id in _local.readPendingSyncIds()) {
      final task = overlay[id];
      if (task == null) {
        await _local.removePendingSync(id);
        continue;
      }
      try {
        if (task.isLocalOnly) {
          await _remote.createTask(
            todo: task.title,
            completed: task.isCompleted,
          );
        } else {
          await _remote.updateTask(
            int.parse(task.id),
            todo: task.title,
            completed: task.isCompleted,
          );
        }
        await _local.removePendingSync(id);
      } on Exception catch (e) {
        log('sync retry still failing for $id', error: e);
      }
    }
  }
}
