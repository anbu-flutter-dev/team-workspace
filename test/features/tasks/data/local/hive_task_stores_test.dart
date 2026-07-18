import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:team_workspace/features/tasks/data/local/pending_sync_store.dart';
import 'package:team_workspace/features/tasks/data/local/task_cache_store.dart';
import 'package:team_workspace/features/tasks/data/local/task_overlay_store.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

// Regression coverage for a bug mocked repository tests can't catch: Hive
// only guarantees Map<String, dynamic> shape at the top level of what it
// reads back. A nested object field (assignedUser) used to come back as
// Map<dynamic, dynamic>, which blew up the generated fromJson's
// `as Map<String, dynamic>` cast one level deeper.
//
// Reading immediately after writing in the same session isn't enough to
// reproduce this — Hive serves that from its in-memory write cache, which
// still holds the original, correctly-typed object. The bug only shows up
// once the box is actually re-read from disk, i.e. on every app restart
// (which is exactly where the real crash fired: syncPendingOperations
// reading the overlay box back on startup). So these tests close and
// reopen the box between write and read to force a genuine deserialize.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('team_workspace_hive_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  final task = Task(
    id: '1',
    title: 'Buy groceries',
    description: 'Milk, eggs, bread',
    priority: TaskPriority.medium,
    dueDate: DateTime(2026, 1, 1),
    status: TaskStatus.pending,
    assignedUser: const AssignedUser(name: 'Aditi Rao'),
  );

  test(
    'TaskOverlayStore survives a real Hive close/reopen with a nested AssignedUser',
    () async {
      final writeBox = await Hive.openBox('overlay_test');
      await TaskOverlayStore(writeBox).save(task);
      await writeBox.close();

      final readBox = await Hive.openBox('overlay_test');
      final roundTripped = TaskOverlayStore(readBox).readAll()['1'];

      expect(roundTripped, task);
    },
  );

  test(
    'TaskCacheStore survives a real Hive close/reopen with a nested AssignedUser',
    () async {
      final writeBox = await Hive.openBox('cache_test');
      await TaskCacheStore(writeBox).write([task]);
      await writeBox.close();

      final readBox = await Hive.openBox('cache_test');
      final roundTripped = TaskCacheStore(readBox).read();

      expect(roundTripped, [task]);
    },
  );

  test('PendingSyncStore.read() survives being iterated while remove() is '
      'called mid-loop, mirroring syncPendingOperations', () async {
    final box = await Hive.openBox('pending_sync_test');
    final store = PendingSyncStore(box);
    await store.add('1');
    await store.add('2');
    await store.add('3');

    // Same shape as TaskRepositoryImpl.syncPendingOperations: iterate the
    // ids read once, removing each as it's processed. A read() that
    // returns a lazy cast view over Hive's own stored list (instead of a
    // copy) throws ConcurrentModificationError here, because remove()
    // mutates that same underlying list mid-iteration.
    final processed = <String>[];
    for (final id in store.read()) {
      processed.add(id);
      await store.remove(id);
    }

    expect(processed, ['1', '2', '3']);
    expect(store.read(), isEmpty);
  });
}
