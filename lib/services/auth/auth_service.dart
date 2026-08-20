import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthService {
  /// Sign in anonymously.
  Future<UserCredential> signInAnonymously();

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail(String email, String password);

  /// Register a new user with email and password.
  Future<UserCredential> register(String email, String password);

  /// Link an anonymous account with email and password.
  Future<UserCredential> linkWithEmail(String email, String password);

  /// Sign out the current user.
  Future<void> signOut();

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges;

  /// Get the current user.
  User? get currentUser;

  /// Check if current user is anonymous.
  bool get isAnonymous;

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email);
}
