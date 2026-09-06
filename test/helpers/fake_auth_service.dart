import 'dart:async';

import 'package:soma_app/application/auth/auth_service.dart';

/// Controllable [AuthService] double for tests.
///
/// Successful sign-in/sign-up and sign-out emit on the state stream, mirroring
/// the behaviour of the real Supabase-backed service.
class FakeAuthService implements AuthService {
  final _states = StreamController<AuthStateChange>.broadcast(sync: true);

  AuthResult nextSignUpResult = const AuthFailure('no result');
  AuthResult nextSignInResult = const AuthFailure('no result');
  AuthResult nextSignInWithGoogleResult = const AuthFailure('no result');
  PasswordRecoveryResult nextResetPasswordResult =
      const PasswordRecoveryRequestAccepted();
  PasswordUpdateResult nextUpdatePasswordResult = const PasswordUpdateSuccess();
  bool signOutCalled = false;

  @override
  Stream<AuthStateChange> authStateChanges() => _states.stream;

  /// Emits a signed-in/signed-out state change.
  void emit(SessionUser? user) {
    _states.add(
      AuthStateChange(
        user == null ? AuthEvent.signedOut : AuthEvent.signedIn,
        user,
      ),
    );
  }

  /// Emits an initial-session (restored) state change.
  void emitInitialSession(SessionUser? user) {
    _states.add(AuthStateChange(AuthEvent.initialSession, user));
  }

  /// Emits a password recovery state change.
  void emitPasswordRecovery(SessionUser user) {
    _states.add(AuthStateChange(AuthEvent.passwordRecovery, user));
  }

  /// Emits a user-updated state change (e.g. password updated during recovery).
  void emitUserUpdated(SessionUser? user) {
    _states.add(AuthStateChange(AuthEvent.userUpdated, user));
  }

  /// Emits an error on the state stream, mirroring a provider network error.
  void emitError(Object error) => _states.addError(error);

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final result = nextSignUpResult;
    if (result is AuthSuccess) {
      emit(result.user);
    }
    return result;
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final result = nextSignInResult;
    if (result is AuthSuccess) {
      emit(result.user);
    }
    return result;
  }

  @override
  Future<AuthResult> signInWithGoogle() async => nextSignInWithGoogleResult;

  @override
  Future<PasswordRecoveryResult> resetPasswordForEmail(String email) async =>
      nextResetPasswordResult;

  @override
  Future<PasswordUpdateResult> updatePassword(String newPassword) async =>
      nextUpdatePasswordResult;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    emit(null);
  }

  Future<void> dispose() => _states.close();
}
