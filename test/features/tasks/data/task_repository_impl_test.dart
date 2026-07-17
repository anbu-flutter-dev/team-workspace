import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:team_workspace/features/tasks/data/local/task_local_datasource.dart';
import 'package:team_workspace/features/tasks/data/models/task_dto.dart';
import 'package:team_workspace/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

class MockConnectivity extends Mock implements Connectivity {}

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
  late MockTaskLocalDataSource local;
  late MockConnectivity connectivity;
  late TaskRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_overlayTask('fallback'));
  });

  setUp(() {
    remote = MockTaskRemoteDataSource();
    local = MockTaskLocalDataSource();
    connectivity = MockConnectivity();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream.empty());
    when(() => local.writeOverlayEntry(any())).thenAnswer((_) async {});
    when(() => local.writeCachedTasks(any())).thenAnswer((_) async {});
    when(() => local.enqueuePendingSync(any())).thenAnswer((_) async {});
    when(() => local.removePendingSync(any())).thenAnswer((_) async {});
    repository = TaskRepositoryImpl(remote, local, connectivity);
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
        () => local.readOverlay(),
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
        when(() => local.readOverlay()).thenReturn({
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

  group('offline queue', () {
    test(
      'createTask enqueues for retry instead of calling remote when offline',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        await repository.createTask(
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
        verify(() => local.enqueuePendingSync(any())).called(1);
      },
    );

    test('createTask calls remote directly when online', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => remote.createTask(
          todo: any(named: 'todo'),
          completed: any(named: 'completed'),
        ),
      ).thenAnswer((_) async {});

      await repository.createTask(
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
      verifyNever(() => local.enqueuePendingSync(any()));
    });

    test(
      'updateTask never calls remote for a local-only (unsynced) task',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        await repository.updateTask(_overlayTask('local_999'));

        verifyNever(
          () => remote.updateTask(
            any(),
            todo: any(named: 'todo'),
            completed: any(named: 'completed'),
          ),
        );
        verifyNever(() => local.enqueuePendingSync(any()));
      },
    );

    test(
      'syncPendingOperations replays queued ids and clears them on success',
      () async {
        when(
          () => connectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => local.readPendingSyncIds()).thenReturn(['5']);
        when(() => local.readOverlay()).thenReturn({'5': _overlayTask('5')});
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
        verify(() => local.removePendingSync('5')).called(1);
      },
    );
  });
}
