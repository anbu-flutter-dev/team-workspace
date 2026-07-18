import 'package:hive_ce/hive_ce.dart';
import 'package:team_workspace/core/utils/json_normalize.dart';
import 'package:team_workspace/features/tasks/data/models/task_model.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

/// Snapshot of the last task list that was successfully loaded.
///
/// Purely a fallback: if fetching page 1 fails because there's no network,
/// the dashboard shows whatever is stored here instead of an empty screen,
/// with a "showing cached data" banner.
class TaskCacheStore {
  TaskCacheStore(this._box);

  final Box<dynamic> _box;

  static const String _key = 'last_loaded_tasks';

  List<Task>? read() {
    final json = _box.get(_key);
    if (json is! List) return null;
    return json
        .whereType<Map>()
        .map((entry) => TaskModel.fromJson(normalizeJsonMap(entry)).toEntity())
        .toList();
  }

  Future<void> write(List<Task> tasks) {
    return _box.put(
      _key,
      tasks.map((task) => TaskModel.fromEntity(task).toJson()).toList(),
    );
  }
}
