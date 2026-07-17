import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/error/failure.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_page.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_state.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}

class MockTaskRepository extends Mock implements TaskRepository {}

Task _task(String id) => Task(
  id: id,
  title: 'Task $id',
  description: 'Description $id',
  priority: TaskPriority.medium,
  dueDate: DateTime(2026, 1, 1),
  status: TaskStatus.pending,
  assignedUser: const AssignedUser(name: 'Aditi Rao'),
);

void main() {
  late MockGetTasksUseCase getTasks;
  late MockTaskRepository repository;

  setUp(() {
    getTasks = MockGetTasksUseCase();
    repository = MockTaskRepository();
    when(() => repository.taskUpdates).thenAnswer((_) => const Stream.empty());
    when(() => repository.syncPendingOperations()).thenAnswer((_) async {});
  });

  TaskListBloc buildBloc() => TaskListBloc(getTasks, repository);

  group('TaskListStarted', () {
    blocTest<TaskListBloc, TaskListState>(
      'emits [Loading, LoadSuccess] when the first page loads',
      setUp: () {
        when(() => getTasks(page: 1)).thenAnswer(
          (_) async => Ok(
            TaskPage(
              tasks: [_task('1'), _task('2')],
              hasMore: true,
              isFromCache: false,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TaskListStarted()),
      expect: () => [
        const TaskListLoading(),
        isA<TaskListLoadSuccess>()
            .having((s) => s.tasks.length, 'tasks.length', 2)
            .having((s) => s.hasMore, 'hasMore', true)
            .having((s) => s.currentPage, 'currentPage', 1),
      ],
    );

    blocTest<TaskListBloc, TaskListState>(
      'emits [Loading, LoadFailure] when the first page fails',
      setUp: () {
        when(
          () => getTasks(page: 1),
        ).thenAnswer((_) async => const Err(NetworkFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TaskListStarted()),
      expect: () => [const TaskListLoading(), isA<TaskListLoadFailure>()],
    );
  });

  group('TaskListNextPageRequested', () {
    blocTest<TaskListBloc, TaskListState>(
      'appends the next page and advances currentPage',
      setUp: () {
        when(() => getTasks(page: 1)).thenAnswer(
          (_) async => Ok(
            TaskPage(tasks: [_task('1')], hasMore: true, isFromCache: false),
          ),
        );
        when(() => getTasks(page: 2)).thenAnswer(
          (_) async => Ok(
            TaskPage(tasks: [_task('2')], hasMore: false, isFromCache: false),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TaskListStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TaskListNextPageRequested());
      },
      skip: 2,
      // _onNextPageRequested has a deliberate 2s delay before fetching.
      wait: const Duration(seconds: 3),
      expect: () => [
        isA<TaskListLoadSuccess>().having(
          (s) => s.isLoadingNextPage,
          'isLoadingNextPage',
          true,
        ),
        isA<TaskListLoadSuccess>()
            .having((s) => s.tasks.length, 'tasks.length', 2)
            .having((s) => s.currentPage, 'currentPage', 2)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<TaskListBloc, TaskListState>(
      'sets an inline paginationError without dropping already-loaded tasks',
      setUp: () {
        when(() => getTasks(page: 1)).thenAnswer(
          (_) async => Ok(
            TaskPage(tasks: [_task('1')], hasMore: true, isFromCache: false),
          ),
        );
        when(
          () => getTasks(page: 2),
        ).thenAnswer((_) async => const Err(ServerFailure('boom')));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TaskListStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TaskListNextPageRequested());
      },
      skip: 2,
      // _onNextPageRequested has a deliberate 2s delay before fetching.
      wait: const Duration(seconds: 3),
      expect: () => [
        isA<TaskListLoadSuccess>().having(
          (s) => s.isLoadingNextPage,
          'isLoadingNextPage',
          true,
        ),
        isA<TaskListLoadSuccess>()
            .having((s) => s.tasks.length, 'tasks.length', 1)
            .having((s) => s.paginationError, 'paginationError', 'boom'),
      ],
    );

    blocTest<TaskListBloc, TaskListState>(
      'does nothing when hasMore is false',
      setUp: () {
        when(() => getTasks(page: 1)).thenAnswer(
          (_) async => Ok(
            TaskPage(tasks: [_task('1')], hasMore: false, isFromCache: false),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TaskListStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TaskListNextPageRequested());
      },
      skip: 2,
      expect: () => <TaskListState>[],
      verify: (_) {
        verifyNever(() => getTasks(page: 2));
      },
    );
  });

  group('TaskListRefreshRequested', () {
    blocTest<TaskListBloc, TaskListState>(
      'resets to a fresh page 1',
      setUp: () {
        var callCount = 0;
        when(() => getTasks(page: 1)).thenAnswer((_) async {
          callCount++;
          // Second call simulates a newly-created task showing up after refresh.
          final tasks = callCount == 1
              ? [_task('1')]
              : [_task('3'), _task('1')];
          return Ok(TaskPage(tasks: tasks, hasMore: false, isFromCache: false));
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const TaskListStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TaskListRefreshRequested());
      },
      skip: 2,
      expect: () => [
        isA<TaskListLoadSuccess>()
            .having((s) => s.tasks.length, 'tasks.length', 2)
            .having((s) => s.currentPage, 'currentPage', 1),
      ],
    );
  });
}
