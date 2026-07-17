import 'package:hive_ce/hive_ce.dart';
import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/di/hive_boxes.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

abstract interface class TaskLocalDataSource {
  /// Overrides keyed by task id — created/edited/toggled tasks live here
  /// until (theoretically) the backend would persist them.
  Map<String, Task> readOverlay();

  Future<void> writeOverlayEntry(Task task);

  List<Task>? readCachedTasks();

  Future<void> writeCachedTasks(List<Task> tasks);

  /// Task ids whose remote write was skipped or failed and still needs a replay.
  List<String> readPendingSyncIds();

  Future<void> enqueuePendingSync(String id);

  Future<void> removePendingSync(String id);
}

@LazySingleton(as: TaskLocalDataSource)
class HiveTaskLocalDataSource implements TaskLocalDataSource {
  HiveTaskLocalDataSource(
    @Named(HiveBoxes.taskOverlay) this._overlayBox,
    @Named(HiveBoxes.taskCache) this._cacheBox,
    @Named(HiveBoxes.writeQueue) this._queueBox,
  );

  final Box<dynamic> _overlayBox;
  final Box<dynamic> _cacheBox;
  final Box<dynamic> _queueBox;

  static const String _cacheKey = 'tasks';
  static const String _queueKey = 'pending_ids';

  @override
  Map<String, Task> readOverlay() {
    final result = <String, Task>{};
    for (final key in _overlayBox.keys) {
      final raw = _overlayBox.get(key);
      if (raw is Map) {
        result[key as String] = Task.fromJson(Map<String, dynamic>.from(raw));
      }
    }
    return result;
  }

  @override
  Future<void> writeOverlayEntry(Task task) =>
      _overlayBox.put(task.id, task.toJson());

  @override
  List<Task>? readCachedTasks() {
    final raw = _cacheBox.get(_cacheKey);
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> writeCachedTasks(List<Task> tasks) {
    return _cacheBox.put(_cacheKey, tasks.map((t) => t.toJson()).toList());
  }

  @override
  List<String> readPendingSyncIds() {
    final raw = _queueBox.get(_queueKey);
    if (raw is! List) return [];
    return raw.cast<String>();
  }

  @override
  Future<void> enqueuePendingSync(String id) {
    final ids = readPendingSyncIds();
    if (!ids.contains(id)) ids.add(id);
    return _queueBox.put(_queueKey, ids);
  }

  @override
  Future<void> removePendingSync(String id) {
    final ids = readPendingSyncIds()..remove(id);
    return _queueBox.put(_queueKey, ids);
  }
}
