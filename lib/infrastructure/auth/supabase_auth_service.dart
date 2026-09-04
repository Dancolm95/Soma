import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/auth/auth_service.dart';
import 'package:soma_app/infrastructure/auth/auth_error_messages.dart';

/// Supabase-backed implementation of [AuthService].
///
/// Session persistence and restoration are handled by supabase_flutter's
/// [Supabase.initialize]; no tokens are stored or managed here.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  Stream<SessionUser?> authStateChanges() =>
      _auth.onAuthStateChange.map((state) {
        final user = state.session?.user;
        return user == null ? null : _toSessionUser(user);
      });

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      final session = response.session;
      if (session == null) {
        return const EmailConfirmationRequired();
      }
      return AuthSuccess(user: _toSessionUser(session.user));
    } on AuthException catch (error) {
      return AuthFailure(signUpErrorMessage(error));
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = response.session;
      if (session == null) {
        return const AuthFailure('No se pudo iniciar sesión.');
      }
      return AuthSuccess(user: _toSessionUser(session.user));
    } on AuthException catch (error) {
      return AuthFailure(signInErrorMessage(error));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  SessionUser _toSessionUser(User user) => SessionUser(email: user.email);
}
