import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:team_workspace/core/error/exceptions.dart';
import 'package:team_workspace/core/error/failure.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/core/network/api_constants.dart';
import 'package:team_workspace/core/utils/log.dart';
import 'package:team_workspace/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/tasks/data/local/pending_sync_store.dart';
import 'package:team_workspace/features/tasks/data/local/task_cache_store.dart';
import 'package:team_workspace/features/tasks/data/local/task_overlay_store.dart';
import 'package:team_workspace/features/tasks/data/models/task_dto_mapper.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_page.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/tasks/domain/task_enrichment.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(
    this._remote,
    this._overlay,
    this._cache,
    this._pendingSync,
    this._connectivity,
  ) {
    // Not stored: this repository is a singleton for the app's lifetime, so
    // there's no meaningful moment to cancel the subscription anyway.
    _connectivity.onConnectivityChanged.listen((results) {
      if (_isOnline(results)) unawaited(syncPendingOperations());
    });
  }

  final TaskRemoteDataSource _remote;
  final TaskOverlayStore _overlay;
  final TaskCacheStore _cache;
  final PendingSyncStore _pendingSync;
  final Connectivity _connectivity;

  final StreamController<Task> _taskUpdatesController =
      StreamController.broadcast();

  @override
  Stream<Task> get taskUpdates => _taskUpdatesController.stream;

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  Future<bool> _checkIsOnline() async =>
      _isOnline(await _connectivity.checkConnectivity());

  @override
  Future<Result<TaskPage>> getTasks({required int page}) async {
    try {
      final response = await _remote.fetchTasks(page: page);
      final overlay = _overlay.readAll();

      // An overlay entry always wins — it holds the real state for anything
      // created or edited locally, while dummyjson only ever knows the
      // original, unedited version.
      final apiTasks = response.todos
          .map((dto) => overlay[dto.id.toString()] ?? dto.toEntity())
          .toList();

      final tasks = page == 1
          ? [..._localOnlyTasksNewestFirst(overlay), ...apiTasks]
          : apiTasks;
      if (page == 1) unawaited(_cache.write(tasks));

      final hasMore = response.todos.length == ApiConstants.pageSize;
      return Ok(TaskPage(tasks: tasks, hasMore: hasMore, isFromCache: false));
    } on NetworkException {
      return _cachedPageOrFailure(page, const NetworkFailure());
    } on ServerException catch (e) {
      return _cachedPageOrFailure(page, ServerFailure(e.message));
    } catch (e) {
      // Deliberately bare, not `on Exception` — a malformed response can
      // throw a TypeError (an Error, not an Exception) partway through
      // parsing, and that still has to resolve into a Result. Left
      // uncaught here, it would escape the bloc's event handler and leave
      // the dashboard stuck on its loading spinner forever, with no error
      // shown and no cached fallback.
      log('unexpected getTasks failure', error: e);
      return _cachedPageOrFailure(page, const ServerFailure());
    }
  }

  Result<TaskPage> _cachedPageOrFailure(int page, Failure failure) {
    if (page == 1) {
      final cached = _cache.read();
      if (cached != null) {
        return Ok(TaskPage(tasks: cached, hasMore: false, isFromCache: true));
      }
    }
    return Err(failure);
  }

  /// Tasks created on this device that dummyjson has never seen — these
  /// have a `local_<createdAt>` id instead of a numeric one, and only show
  /// up on page 1, newest first.
  List<Task> _localOnlyTasksNewestFirst(Map<String, Task> overlay) {
    final localOnlyTasks = overlay.values
        .where((task) => task.isLocalOnly)
        .toList();
    localOnlyTasks.sort(
      (a, b) => _createdAtMillis(b.id).compareTo(_createdAtMillis(a.id)),
    );
    return localOnlyTasks;
  }

  int _createdAtMillis(String localId) =>
      int.parse(localId.substring('local_'.length));

  @override
  Future<Result<Task>> getTaskById(String id) async {
    final overlayHit = _overlay.readAll()[id];
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
    } catch (e) {
      log('unexpected getTaskById failure', error: e);
      return const Err(ServerFailure());
    }
  }

  @override
  Future<Result<Task>> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
  }) {
    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final task = Task(
      id: id,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      status: TaskStatus.pending,
      assignedUser: TaskEnrichment.assignedUserFor(id.hashCode),
    );
    return _saveLocallyThenSyncRemote(
      task,
      remoteCall: () => _remote.createTask(todo: title, completed: false),
    );
  }

  @override
  Future<Result<Task>> updateTask(Task task) {
    // A task that's never synced yet has no numeric id for the API to look
    // up — its only remote call left is the create it's still waiting on.
    final remoteCall = task.isLocalOnly
        ? null
        : () => _remote.updateTask(
            int.parse(task.id),
            todo: task.title,
            completed: task.isCompleted,
          );
    return _saveLocallyThenSyncRemote(task, remoteCall: remoteCall);
  }

  /// Every write (create, edit, status toggle) follows the same shape:
  /// save to the overlay first — that always "succeeds" from the user's
  /// point of view — then best-effort tell the real API. Offline, or a
  /// failed call, queues the id for [syncPendingOperations] instead of
  /// surfacing an error, since dummyjson wouldn't have kept the write
  /// anyway; only a failed *local* save is a real failure.
  Future<Result<Task>> _saveLocallyThenSyncRemote(
    Task task, {
    required Future<void> Function()? remoteCall,
  }) async {
    try {
      await _overlay.save(task);
    } on Exception {
      return const Err(CacheFailure());
    }
    _taskUpdatesController.add(task);

    if (remoteCall != null) {
      if (await _checkIsOnline()) {
        try {
          await remoteCall();
        } on Exception catch (e) {
          log('remote write failed, queuing for retry', error: e);
          await _pendingSync.add(task.id);
        }
      } else {
        await _pendingSync.add(task.id);
      }
    }
    return Ok(task);
  }

  @override
  Future<void> syncPendingOperations() async {
    if (!await _checkIsOnline()) return;

    final overlay = _overlay.readAll();
    for (final id in _pendingSync.read()) {
      final task = overlay[id];
      if (task == null) {
        await _pendingSync.remove(id);
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
        await _pendingSync.remove(id);
      } on Exception catch (e) {
        log('sync retry still failing for $id', error: e);
      }
    }
  }
}
