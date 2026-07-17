/// FirebaseAuthException.code is machine-readable — never surface it directly to users.
String mapFirebaseAuthErrorCode(String code) {
  switch (code) {
    case 'invalid-email':
      return 'That email address looks invalid.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
      return 'No account found with that email.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'email-already-in-use':
      return 'An account already exists with that email.';
    case 'operation-not-allowed':
      return 'Email/password sign-in is not enabled.';
    case 'weak-password':
      return 'That password is too weak — use at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error — check your connection and try again.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
