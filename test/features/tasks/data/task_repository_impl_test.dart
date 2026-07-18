import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/analytics/analytics_service.dart';
import 'package:team_workspace/core/error/exceptions.dart';
import 'package:team_workspace/core/error/failure.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/tasks/data/local/pending_sync_store.dart';
import 'package:team_workspace/features/tasks/data/local/task_cache_store.dart';
import 'package:team_workspace/features/tasks/data/local/task_overlay_store.dart';
import 'package:team_workspace/features/tasks/data/models/task_dto.dart';
import 'package:team_workspace/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_save_outcome.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class MockTaskOverlayStore extends Mock implements TaskOverlayStore {}

class MockTaskCacheStore extends Mock implements TaskCacheStore {}

class MockPendingSyncStore extends Mock implements PendingSyncStore {}

class MockConnectivity extends Mock implements Connectivity {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

Task _overlayTask(String id, {String title = 'Overlay title'}) => Task(
  id: id,
  title: title,
  description: 'Overlay description',
  priority: TaskPriority.high,
  dueDate: DateTime(2026, 1, 1),
  status: TaskStatus.pending,
  assignedUser: const AssignedUser(name: 'Aditi Rao'),
);

void main() {
  late MockTaskRemoteDataSource remote;
  late MockTaskOverlayStore overlay;
  late MockTaskCacheStore cache;
  late MockPendingSyncStore pendingSync;
  late MockConnectivity connectivity;
  late MockAnalyticsService analytics;
  late TaskRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_overlayTask('fallback'));
  });

  setUp(() {
    remote = MockTaskRemoteDataSource();
    overlay = MockTaskOverlayStore();
    cache = MockTaskCacheStore();
    pendingSync = MockPendingSyncStore();
    connectivity = MockConnectivity();
    analytics = MockAnalyticsService();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());
    when(() => overlay.save(any())).thenAnswer((_) async {});
    when(() => cache.write(any())).thenAnswer((_) async {});
    when(() => pendingSync.add(any())).thenAnswer((_) async {});
    when(() => pendingSync.remove(any())).thenAnswer((_) async {});
    when(
      () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
    ).thenReturn(null);
    repository = TaskRepositoryImpl(
      remote,
      overlay,
      cache,
      pendingSync,
      connectivity,
      analytics,
    );
  });

  group('getTasks overlay merge', () {
    test('an overlay entry overrides the matching API task by id', () async {
      when(() => remote.fetchTasks(page: 1)).thenAnswer(
        (_) async => TaskListResponseDto(
          todos: [
            TaskDto(id: 1, todo: 'Original 1', completed: false, userId: 1),
            TaskDto(id: 2, todo: 'Original 2', completed: false, userId: 1),
          ],
          total: 2,
          skip: 0,
          limit: 10,
        ),
      );
      when(
        () => overlay.readAll(),
      ).thenReturn({'2': _overlayTask('2', title: 'Edited 2')});

      final result = await repository.getTasks(page: 1);

      final page = result.fold((_) => null, (p) => p);
      expect(page, isNotNull);
      expect(page!.tasks.firstWhere((t) => t.id == '2').title, 'Edited 2');
      expect(page.tasks.firstWhere((t) => t.id == '1').title, 'Original 1');
    });

    test(
      'local-only overlay tasks are prepended, newest first, on page 1',
      () async {
        when(() => remote.fetchTasks(page: 1)).thenAnswer(
          (_) async => TaskListResponseDto(
            todos: [
              TaskDto(id: 1, todo: 'Original 1', completed: false, userId: 1),
            ],
            total: 1,
            skip: 0,
            limit: 10,
          ),
        );
        when(() => overlay.readAll()).thenReturn({
          'local_100': _overlayTask('local_100', title: 'Older local'),
          'local_200': _overlayTask('local_200', title: 'Newer local'),
        });

        final result = await repository.getTasks(page: 1);
        final page = result.fold((_) => null, (p) => p);

        expect(page!.tasks.map((t) => t.id).toList(), [
          'local_200',
          'local_100',
          '1',
        ]);
      },
    );
  });

  group('getTasks failure handling', () {
    // Regression coverage: any failure mode has to resolve into a Result.
    // Before this fix, only NetworkException/ServerException were caught —
    // anything else escaped getTasks uncaught, which left TaskListBloc
    // stuck on its loading state forever (no error, no cached fallback).
    test('NetworkException falls back to cached data when available', () async {
      when(() => remote.fetchTasks(page: 1)).thenThrow(NetworkException());
      when(() => overlay.readAll()).thenReturn({});
      when(
        () => cache.read(),
      ).thenReturn([_overlayTask('1', title: 'Cached task')]);

      final result = await repository.getTasks(page: 1);

      final page = result.fold((_) => null, (p) => p);
      expect(page, isNotNull);
      expect(page!.isFromCache, isTrue);
      expect(page.tasks.single.title, 'Cached task');
    });

    test('NetworkException with no cache returns NetworkFailure', () async {
      when(() => remote.fetchTasks(page: 1)).thenThrow(NetworkException());
      when(() => cache.read()).thenReturn(null);

      final result = await repository.getTasks(page: 1);

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<NetworkFailure>());
    });

    test(
      'an unexpected Error (not Exception) still resolves into a Result',
      () async {
        // TypeError extends Error, not Exception — `on Exception catch` alone
        // would not have caught this, which is exactly how this bug shipped.
        when(() => remote.fetchTasks(page: 1)).thenThrow(TypeError());
        when(() => cache.read()).thenReturn(null);

        final result = await repository.getTasks(page: 1);

        final failure = result.fold((f) => f, (_) => null);
        expect(failure, isA<ServerFailure>());
      },
    );
  });

  group('offline queue', () {
    test(
      'createTask enqueues for retry instead of calling remote when offline, '
      'and flags the outcome as pendingSync',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await repository.createTask(
          title: 'Offline task',
          description: 'desc',
          priority: TaskPriority.low,
          dueDate: DateTime(2026, 1, 1),
        );

        verifyNever(
          () => remote.createTask(
            todo: any(named: 'todo'),
            completed: any(named: 'completed'),
          ),
        );
        verify(() => pendingSync.add(any())).called(1);
        final outcome = result.fold((_) => null, (o) => o);
        expect(outcome, isNotNull);
        expect(outcome!.syncStatus, SyncStatus.pendingSync);
        expect(outcome.isPendingSync, isTrue);
      },
    );

    test('createTask calls remote directly when online, and flags the outcome '
        'as synced', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => remote.createTask(
          todo: any(named: 'todo'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.createTask(
        title: 'Online task',
        description: 'desc',
        priority: TaskPriority.low,
        dueDate: DateTime(2026, 1, 1),
      );

      verify(
        () => remote.createTask(
          todo: any(named: 'todo'),
          completed: any(named: 'completed'),
        ),
      ).called(1);
      verifyNever(() => pendingSync.add(any()));
      final outcome = result.fold((_) => null, (o) => o);
      expect(outcome, isNotNull);
      expect(outcome!.syncStatus, SyncStatus.synced);
      expect(outcome.isPendingSync, isFalse);
    });

    test(
      'createTask queues for retry and flags pendingSync when the remote '
      'call fails while online — the write must not look fully synced',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(
          () => remote.createTask(
            todo: any(named: 'todo'),
            completed: any(named: 'completed'),
          ),
        ).thenThrow(Exception('boom'));

        final result = await repository.createTask(
          title: 'Flaky task',
          description: 'desc',
          priority: TaskPriority.low,
          dueDate: DateTime(2026, 1, 1),
        );

        verify(() => pendingSync.add(any())).called(1);
        final outcome = result.fold((_) => null, (o) => o);
        expect(outcome, isNotNull);
        expect(outcome!.syncStatus, SyncStatus.pendingSync);
      },
    );

    test('updateTask never calls remote for a local-only (unsynced) task, and '
        'flags the outcome as pendingSync', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final result = await repository.updateTask(_overlayTask('local_999'));

      verifyNever(
        () => remote.updateTask(
          any(),
          todo: any(named: 'todo'),
          completed: any(named: 'completed'),
        ),
      );
      verifyNever(() => pendingSync.add(any()));
      final outcome = result.fold((_) => null, (o) => o);
      expect(outcome, isNotNull);
      expect(outcome!.syncStatus, SyncStatus.pendingSync);
    });

    test(
      'syncPendingOperations replays queued ids and clears them on success',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => pendingSync.read()).thenReturn(['5']);
        when(() => overlay.readAll()).thenReturn({'5': _overlayTask('5')});
        when(
          () => remote.updateTask(
            any(),
            todo: any(named: 'todo'),
            completed: any(named: 'completed'),
          ),
        ).thenAnswer((_) async {});

        await repository.syncPendingOperations();

        verify(
          () => remote.updateTask(
            5,
            todo: any(named: 'todo'),
            completed: any(named: 'completed'),
          ),
        ).called(1);
        verify(() => pendingSync.remove('5')).called(1);
      },
    );
  });
}
