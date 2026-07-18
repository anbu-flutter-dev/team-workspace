import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/core/theme/theme_cubit.dart';
import 'package:team_workspace/features/auth/domain/entities/app_user.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_state.dart';
import 'package:team_workspace/features/tasks/presentation/pages/dashboard_page.dart';

class MockTaskListBloc extends MockBloc<TaskListEvent, TaskListState>
    implements TaskListBloc {}

class MockThemeCubit extends MockCubit<ThemeMode> implements ThemeCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

const _user = AppUser(id: '1', email: 'user@example.com');

Task _task(String id, String title) => Task(
  id: id,
  title: title,
  description: 'Description $id',
  priority: TaskPriority.medium,
  dueDate: DateTime(2026, 1, 1),
  status: TaskStatus.pending,
  assignedUser: const AssignedUser(name: 'Aditi Rao'),
);

void main() {
  late MockTaskListBloc bloc;
  late MockThemeCubit themeCubit;
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AuthSignOutRequested());
  });

  setUp(() {
    bloc = MockTaskListBloc();
    if (getIt.isRegistered<TaskListBloc>()) getIt.unregister<TaskListBloc>();
    getIt.registerFactory<TaskListBloc>(() => bloc);

    themeCubit = MockThemeCubit();
    when(() => themeCubit.state).thenReturn(ThemeMode.system);

    authBloc = MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(_user),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildSubject() => MaterialApp(
    home: BlocProvider<ThemeCubit>.value(
      value: themeCubit,
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const DashboardPage(),
      ),
    ),
  );

  void stub(TaskListState state) {
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, const Stream<TaskListState>.empty(), initialState: state);
  }

  testWidgets('shows a spinner while the first page is loading', (
    tester,
  ) async {
    stub(const TaskListLoading());

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'shows the empty state with a create CTA when there are no tasks',
    (tester) async {
      stub(
        const TaskListLoadSuccess(tasks: [], currentPage: 1, hasMore: false),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Create a task'), findsOneWidget);
    },
  );

  testWidgets('shows the full-screen error view with a retry button', (
    tester,
  ) async {
    stub(const TaskListLoadFailure('Could not reach the server'));

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Could not reach the server'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('renders each loaded task', (tester) async {
    stub(
      TaskListLoadSuccess(
        tasks: [_task('1', 'Buy groceries'), _task('2', 'Write report')],
        currentPage: 1,
        hasMore: false,
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
  });

  testWidgets('shows a snackbar when sign-out fails', (tester) async {
    stub(const TaskListLoadSuccess(tasks: [], currentPage: 1, hasMore: false));
    whenListen(
      authBloc,
      Stream.fromIterable([const AuthSubmissionFailure('Network error')]),
      initialState: const AuthAuthenticated(_user),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pump();

    expect(find.text('Sign out failed: Network error'), findsOneWidget);
    verify(() => authBloc.add(const AuthSignOutRequested())).called(1);
  });
}
