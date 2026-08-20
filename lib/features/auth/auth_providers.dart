import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../services/firestore/firestore_service.dart';
import '../../services/firestore/firebase_firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/race_model.dart';
import '../splash/splash_providers.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirebaseFirestoreService();
});

// Stream provider for auth state
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user model provider
final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  try {
    final firestoreService = ref.read(firestoreServiceProvider);
    var userModel = await firestoreService.getUserData(user.uid);
    if (userModel == null) {
      // Create user document
      userModel = UserModel.empty(user.uid);
      await firestoreService.createUser(userModel);
    }
    return userModel;
  } catch (e) {
    return UserModel.empty(user.uid);
  }
});

// Provider for current race (from local storage)
final currentRaceProvider = Provider<RaceModel?>((ref) {
  final storageService = ref.watch(hiveStorageServiceProvider);
  try {
    return storageService.getRace();
  } catch (e) {
    return null;
  }
});

// Provider that checks if user has a race
final hasRaceProvider = Provider<bool>((ref) {
  final race = ref.watch(currentRaceProvider);
  return race != null;
});

// Auth controller state
class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;

  const AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthControllerState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthControllerState());

  Future<bool> signInAnonymously() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signInAnonymously();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'auth_err_sign_in_failed',
      );
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signInWithEmail(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseAuthError(e),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.register(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseAuthError(e),
      );
      return false;
    }
  }

  Future<bool> linkWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.linkWithEmail(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseAuthError(e),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
    } catch (e) {
      state = state.copyWith(errorMessage: 'auth_err_sign_out_failed');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String _parseAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'auth_err_no_account';
        case 'wrong-password':
          return 'auth_err_wrong_password';
        case 'email-already-in-use':
          return 'auth_err_email_in_use';
        case 'weak-password':
          return 'auth_err_weak_password';
        case 'invalid-email':
          return 'auth_err_invalid_email';
        case 'credential-already-in-use':
          return 'auth_err_credential_in_use';
        default:
          return 'auth_err_default';
      }
    }
    return 'auth_err_default';
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});
