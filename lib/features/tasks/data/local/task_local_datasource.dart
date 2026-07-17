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
}

@LazySingleton(as: TaskLocalDataSource)
class HiveTaskLocalDataSource implements TaskLocalDataSource {
  HiveTaskLocalDataSource(
    @Named(HiveBoxes.taskOverlay) this._overlayBox,
    @Named(HiveBoxes.taskCache) this._cacheBox,
  );

  final Box<dynamic> _overlayBox;
  final Box<dynamic> _cacheBox;

  static const String _cacheKey = 'tasks';

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
}
