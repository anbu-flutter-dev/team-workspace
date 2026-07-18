class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{6,}$',
  );

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (!_passwordPattern.hasMatch(value.trim())) {
      return 'Password is too weak. Ensure it is at least 6 characters\nand contains mixed case, a number, and a special character.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? required(
    String? value, {
    required String fieldName,
    int minLength = 5,
    int? maxLength,
  }) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    if (value.length < minLength) {
      return '$fieldName must be $minLength at least characters';
    }
    if (maxLength != null && value.length > maxLength) {
      return '$fieldName must be $maxLength characters or fewer';
    }
    return null;
  }
}
