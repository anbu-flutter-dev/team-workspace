import 'package:hive_ce/hive_ce.dart';
import 'package:team_workspace/core/utils/json_normalize.dart';
import 'package:team_workspace/features/tasks/data/models/task_model.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

/// Remembers the latest version of any task created or edited on this device.
///
/// dummyjson's write endpoints echo back a fake response but never actually
/// save anything server-side. So this box — not the API — is the real
/// source of truth for local changes: every create, edit, or status toggle
/// writes the resulting [Task] here, keyed by id, and every read checks
/// here first before trusting whatever dummyjson returned.
class TaskOverlayStore {
  TaskOverlayStore(this._box);

  final Box<dynamic> _box;

  /// Every locally-known task, keyed by id.
  Map<String, Task> readAll() {
    final tasks = <String, Task>{};
    for (final id in _box.keys) {
      final json = _box.get(id);
      if (json is Map) {
        tasks[id as String] = TaskModel.fromJson(
          normalizeJsonMap(json),
        ).toEntity();
      }
    }
    return tasks;
  }

  Future<void> save(Task task) =>
      _box.put(task.id, TaskModel.fromEntity(task).toJson());
}
