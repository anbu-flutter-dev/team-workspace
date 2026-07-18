import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_state.dart';
import 'package:team_workspace/features/tasks/presentation/widgets/task_form_view.dart';

class MockTaskFormBloc extends MockBloc<TaskFormEvent, TaskFormState>
    implements TaskFormBloc {}

void main() {
  late MockTaskFormBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      TaskFormSubmitted(
        title: 'x',
        description: 'x',
        priority: TaskPriority.low,
        dueDate: DateTime(2026),
      ),
    );
  });

  setUp(() {
    bloc = MockTaskFormBloc();
    whenListen(
      bloc,
      const Stream<TaskFormState>.empty(),
      initialState: const TaskFormInitial(),
    );
    if (getIt.isRegistered<TaskFormBloc>()) getIt.unregister<TaskFormBloc>();
    getIt.registerFactory<TaskFormBloc>(() => bloc);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'shows required-field errors when submitting an empty create form',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TaskFormView()));

      await tester.tap(find.text('Create task'));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Description is required'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    },
  );

  testWidgets(
    'blocks submission with an inline error when the due date is already overdue',
    (tester) async {
      // Editing an existing task whose due date is in the past — the picker's
      // firstDate alone can't catch this, since it only restricts new picks.
      final overdueTask = Task(
        id: '1',
        title: 'Overdue task',
        description: 'This was due yesterday',
        priority: TaskPriority.medium,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.pending,
        assignedUser: const AssignedUser(name: 'Aditi Rao'),
      );

      await tester.pumpWidget(
        MaterialApp(home: TaskFormView(initialTask: overdueTask)),
      );

      // Edit mode adds a Status field, pushing the button below the default
      // test viewport — scroll it into view before tapping.
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.text('Due date must be today or later'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    },
  );
}
