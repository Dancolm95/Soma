import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:soma_app/application/auth/auth_service.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

/// Holds the authentication state of the application and reacts to session
/// changes emitted by the underlying [AuthService].
class AuthController extends ChangeNotifier {
  AuthController(this._authService) {
    _subscription = _authService.authStateChanges().listen(_applySession);
  }

  final AuthService _authService;
  StreamSubscription<SessionUser?>? _subscription;

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

  Future<void> signOut() => _authService.signOut();

  void _applySession(SessionUser? user) {
    _user = user;
    _status = user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
