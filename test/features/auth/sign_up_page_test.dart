import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/auth/presentation/pages/sign_up_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AuthSignInSubmitted(email: '', password: ''));
  });

  setUp(() {
    authBloc = MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthUnauthenticated(),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const SignUpPage(),
      ),
    );
  }

  Future<void> fillFields(
    WidgetTester tester, {
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.enterText(find.byType(TextFormField).at(2), confirmPassword);
  }

  testWidgets('shows required-field errors when submitting empty fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('Sign up'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });

  testWidgets('shows a mismatch error when confirm password differs', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await fillFields(
      tester,
      email: 'user@example.com',
      password: 'password123',
      confirmPassword: 'password456',
    );
    await tester.tap(find.text('Sign up'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(() => authBloc.add(any()));
  });

  testWidgets(
    'dispatches AuthSignUpSubmitted once passwords match and the form is valid',
    (tester) async {
      await tester.pumpWidget(buildSubject());

      await fillFields(
        tester,
        email: 'user@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      verify(
        () => authBloc.add(
          const AuthSignUpSubmitted(
            email: 'user@example.com',
            password: 'password123',
          ),
        ),
      ).called(1);
    },
  );
}
