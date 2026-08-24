import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Signs in anonymously.
  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  /// Returns the existing user or creates an anonymous session when necessary.
  Future<User> ensureAnonymousUser() async {
    final existingUser = currentUser;
    if (existingUser != null) {
      return existingUser;
    }

    final credential = await signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Anonymous sign-in completed without a Firebase user.');
    }

    return user;
  }

  /// Returns the currently authenticated Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Returns the verified Firebase identity for the current session.
  String? get currentUserId => currentUser?.uid;
}
