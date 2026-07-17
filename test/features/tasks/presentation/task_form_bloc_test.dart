import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/error/failure.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:team_workspace/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_state.dart';

class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

void main() {
  late MockCreateTaskUseCase createTask;
  late MockUpdateTaskUseCase updateTask;

  final existingTask = Task(
    id: '42',
    title: 'Old title',
    description: 'Old description',
    priority: TaskPriority.low,
    dueDate: DateTime(2026, 1, 1),
    status: TaskStatus.pending,
    assignedUser: const AssignedUser(name: 'Aditi Rao'),
  );

  setUpAll(() {
    registerFallbackValue(existingTask);
    registerFallbackValue(TaskPriority.medium);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    createTask = MockCreateTaskUseCase();
    updateTask = MockUpdateTaskUseCase();
  });

  TaskFormBloc buildBloc() => TaskFormBloc(createTask, updateTask);

  group('create mode (existingTask == null)', () {
    blocTest<TaskFormBloc, TaskFormState>(
      'calls CreateTaskUseCase and emits [Submitting, SubmitSuccess]',
      setUp: () {
        when(
          () => createTask(
            title: any(named: 'title'),
            description: any(named: 'description'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          ),
        ).thenAnswer((_) async => Ok(existingTask));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        TaskFormSubmitted(
          title: 'New task',
          description: 'New description',
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 2, 1),
        ),
      ),
      expect: () => [const TaskFormSubmitting(), isA<TaskFormSubmitSuccess>()],
      verify: (_) {
        verifyNever(() => updateTask(any()));
      },
    );

    blocTest<TaskFormBloc, TaskFormState>(
      'emits [Submitting, SubmitFailure] when creation fails',
      setUp: () {
        when(
          () => createTask(
            title: any(named: 'title'),
            description: any(named: 'description'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          ),
        ).thenAnswer((_) async => const Err(CacheFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        TaskFormSubmitted(
          title: 'New task',
          description: 'New description',
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 2, 1),
        ),
      ),
      expect: () => [const TaskFormSubmitting(), isA<TaskFormSubmitFailure>()],
    );
  });

  group('edit mode (existingTask != null)', () {
    blocTest<TaskFormBloc, TaskFormState>(
      'calls UpdateTaskUseCase with the merged task and never touches create',
      setUp: () {
        when(() => updateTask(any())).thenAnswer((_) async => Ok(existingTask));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        TaskFormSubmitted(
          title: 'Updated title',
          description: 'Updated description',
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 3, 1),
          status: TaskStatus.completed,
          existingTask: existingTask,
        ),
      ),
      expect: () => [const TaskFormSubmitting(), isA<TaskFormSubmitSuccess>()],
      verify: (_) {
        final captured =
            verify(() => updateTask(captureAny())).captured.single as Task;
        expect(captured.id, existingTask.id);
        expect(captured.title, 'Updated title');
        expect(captured.status, TaskStatus.completed);
        verifyNever(
          () => createTask(
            title: any(named: 'title'),
            description: any(named: 'description'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          ),
        );
      },
    );
  });
}
