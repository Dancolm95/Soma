import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:soma_app/application/auth/auth_service.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticated,
  passwordRecovery,
}

/// Holds the authentication state of the application and reacts to session
/// changes emitted by the underlying [AuthService].
class AuthController extends ChangeNotifier {
  AuthController(this._authService) {
    _subscription = _authService.authStateChanges().listen(
      _applyAuthState,
      onError: _handleAuthStreamError,
    );
  }

  final AuthService _authService;
  StreamSubscription<AuthStateChange>? _subscription;

  AuthStatus _status = AuthStatus.initializing;
  SessionUser? _user;

  AuthStatus get status => _status;
  SessionUser? get user => _user;

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) => _authService.signUp(email: email, password: password);

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) => _authService.signIn(email: email, password: password);

  Future<AuthResult> signInWithGoogle() => _authService.signInWithGoogle();

  Future<PasswordRecoveryResult> resetPasswordForEmail(String email) =>
      _authService.resetPasswordForEmail(email);

  Future<PasswordUpdateResult> updatePassword(String newPassword) async {
    final result = await _authService.updatePassword(newPassword);
    if (result is PasswordUpdateSuccess) {
      // A recovery session is single-use: once the password is updated the
      // session must be closed so the auth stream drives the app back to
      // `unauthenticated` (and AuthGate to the login screen). Doing it here
      // keeps navigation derived from auth state instead of a UI action.
      await _authService.signOut();
    }
    return result;
  }

  Future<void> signOut() => _authService.signOut();

  void _applyAuthState(AuthStateChange state) {
    _user = state.user;
    _status = switch (state.event) {
      AuthEvent.initialSession =>
        state.user == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated,
      AuthEvent.passwordRecovery => AuthStatus.passwordRecovery,
      AuthEvent.signedIn => AuthStatus.authenticated,
      AuthEvent.signedOut => AuthStatus.unauthenticated,
      // Preserve the current status: a token refresh or a password update
      // during recovery must not silently jump into the authenticated area.
      AuthEvent.tokenRefreshed || AuthEvent.userUpdated =>
        _status == AuthStatus.initializing
            ? (state.user == null
                  ? AuthStatus.unauthenticated
                  : AuthStatus.authenticated)
            : _status,
    };
    notifyListeners();
  }

  void _handleAuthStreamError(Object error, StackTrace stackTrace) {
    // The provider may emit network errors on the auth stream. They must not
    // crash the app nor transition the user into an unsafe state. Only the
    // error type is logged, never session or user data.
    debugPrint('Auth state stream error (${error.runtimeType}).');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
