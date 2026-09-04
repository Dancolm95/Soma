import 'dart:async';

import 'package:soma_app/application/auth/auth_service.dart';

/// Controllable [AuthService] double for tests.
///
/// Successful sign-in/sign-up and sign-out emit on the state stream, mirroring
/// the behaviour of the real Supabase-backed service.
class FakeAuthService implements AuthService {
  final _states = StreamController<SessionUser?>.broadcast(sync: true);

  AuthResult nextSignUpResult = const AuthFailure('no result');
  AuthResult nextSignInResult = const AuthFailure('no result');
  bool signOutCalled = false;

  @override
  Stream<SessionUser?> authStateChanges() => _states.stream;

  void emit(SessionUser? user) => _states.add(user);

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final result = nextSignUpResult;
    if (result is AuthSuccess) {
      _states.add(result.user);
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
      _states.add(result.user);
    }
    return result;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _states.add(null);
  }

  Future<void> dispose() => _states.close();
}
