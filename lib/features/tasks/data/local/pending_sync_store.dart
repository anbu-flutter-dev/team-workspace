import 'package:hive_ce/hive_ce.dart';

/// Ids of tasks whose create/edit reached [TaskOverlayStore] but never
/// reached the server — because we were offline, or the request failed.
///
/// Only ids are stored, not full task data. When it's time to replay a
/// pending write, the repository looks up the *current* overlay entry for
/// that id, so a task edited twice while offline is synced once, with its
/// latest data — this store doesn't need to know anything about that.
class PendingSyncStore {
  PendingSyncStore(this._box);

  final Box<dynamic> _box;

  static const String _key = 'pending_task_ids';

  List<String> read() {
    final ids = _box.get(_key);
    return ids is List ? ids.cast<String>() : [];
  }

  Future<void> add(String id) {
    final ids = read();
    if (ids.contains(id)) return Future.value();
    return _box.put(_key, [...ids, id]);
  }

  Future<void> remove(String id) {
    final ids = read()..remove(id);
    return _box.put(_key, ids);
  }
}
