import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth so the repository can be tested against
/// a fake instead of mocking the SDK's concrete class directly.
abstract interface class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;

  User? get currentUser;

  Future<User> signIn({required String email, required String password});

  Future<User> signUp({required String email, required String password});

  Future<void> signOut();
}

class FirebaseAuthDataSource implements AuthRemoteDataSource {
  FirebaseAuthDataSource(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User> signIn({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  @override
  Future<User> signUp({required String email, required String password}) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();
}
