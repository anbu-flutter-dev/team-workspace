import 'package:flutter_test/flutter_test.dart';
import 'package:team_workspace/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty', () => expect(Validators.email(''), isNotNull));
    test(
      'rejects malformed',
      () => expect(Validators.email('not-an-email'), isNotNull),
    );
    test(
      'accepts a valid address',
      () => expect(Validators.email('user@example.com'), isNull),
    );
  });

  group('Validators.password', () {
    test('rejects empty', () => expect(Validators.password(''), isNotNull));
    test(
      'rejects fewer than 6 characters',
      () => expect(Validators.password('12345'), isNotNull),
    );
    test(
      'accepts 6 or more characters',
      () => expect(Validators.password('123456'), isNull),
    );
  });

  group('Validators.confirmPassword', () {
    test(
      'rejects empty',
      () => expect(Validators.confirmPassword('', 'password123'), isNotNull),
    );
    test(
      'rejects a mismatch',
      () =>
          expect(Validators.confirmPassword('other', 'password123'), isNotNull),
    );
    test(
      'accepts a match',
      () => expect(
        Validators.confirmPassword('password123', 'password123'),
        isNull,
      ),
    );
  });

  group('Validators.required', () {
    test(
      'rejects empty',
      () => expect(Validators.required('', fieldName: 'Title'), isNotNull),
    );
    test(
      'rejects whitespace-only',
      () => expect(Validators.required('   ', fieldName: 'Title'), isNotNull),
    );
    test(
      'rejects a value over maxLength',
      () => expect(
        Validators.required('a' * 101, fieldName: 'Title', maxLength: 100),
        isNotNull,
      ),
    );
    test(
      'accepts a non-empty value within maxLength',
      () => expect(
        Validators.required('Buy milk', fieldName: 'Title', maxLength: 100),
        isNull,
      ),
    );
    test(
      'accepts any non-empty value when no maxLength is given',
      () => expect(
        Validators.required('Any description', fieldName: 'Description'),
        isNull,
      ),
    );
  });
}
