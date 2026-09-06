import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/auth/auth_service.dart';
import 'package:soma_app/infrastructure/auth/auth_error_messages.dart';

/// Supabase-backed implementation of [AuthService].
///
/// Session persistence and restoration are handled by supabase_flutter's
/// [Supabase.initialize]; no tokens are stored or managed here.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client, {this.webRedirectUrl});

  final SupabaseClient _client;
  final String? webRedirectUrl;

  static const _androidRedirectTo = 'com.soma.expenses://auth-callback/';

  GoTrueClient get _auth => _client.auth;

  /// Redirect target for auth flows (OAuth, email confirmation, password recovery).
  ///
  /// Android uses the approved deep link; Web uses the build-time redirect
  /// URL, which must be registered in the Supabase Auth allow list.
  String? get _authRedirectTo {
    if (kIsWeb) return webRedirectUrl;
    return _androidRedirectTo;
  }

  @override
  Stream<AuthStateChange> authStateChanges() =>
      _auth.onAuthStateChange.map((state) {
        final user = state.session?.user;
        return AuthStateChange(
          _toAuthEvent(state.event),
          user == null ? null : _toSessionUser(user),
        );
      });

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _authRedirectTo,
      );
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
  Future<AuthResult> signInWithGoogle() async {
    try {
      final launched = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _authRedirectTo,
      );
      if (!launched) {
        return const AuthFailure(
          'No se pudo abrir el navegador para continuar con Google.',
        );
      }
      return const OAuthFlowStarted();
    } on AuthException catch (error) {
      return AuthFailure(oAuthErrorMessage(error));
    }
  }

  @override
  Future<PasswordRecoveryResult> resetPasswordForEmail(String email) async {
    try {
      await _auth.resetPasswordForEmail(email, redirectTo: _authRedirectTo);
      return const PasswordRecoveryRequestAccepted();
    } on AuthException catch (error) {
      debugPrint(
        'Password recovery request failed (${error.code ?? 'no code'}).',
      );
      return const PasswordRecoveryFailure(
        'No se pudo procesar la solicitud. Inténtalo de nuevo.',
      );
    } catch (error) {
      debugPrint('Password recovery request failed (${error.runtimeType}).');
      return const PasswordRecoveryFailure(
        'No se pudo procesar la solicitud. Inténtalo de nuevo.',
      );
    }
  }

  @override
  Future<PasswordUpdateResult> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
      return const PasswordUpdateSuccess();
    } on AuthException catch (error) {
      return PasswordUpdateFailure(_passwordUpdateErrorMessage(error));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  SessionUser _toSessionUser(User user) => SessionUser(email: user.email);

  AuthEvent _toAuthEvent(AuthChangeEvent event) {
    switch (event) {
      case AuthChangeEvent.initialSession:
        return AuthEvent.initialSession;
      case AuthChangeEvent.passwordRecovery:
        return AuthEvent.passwordRecovery;
      case AuthChangeEvent.signedIn:
        return AuthEvent.signedIn;
      case AuthChangeEvent.signedOut:
        return AuthEvent.signedOut;
      case AuthChangeEvent.tokenRefreshed:
        return AuthEvent.tokenRefreshed;
      case AuthChangeEvent.userUpdated:
        return AuthEvent.userUpdated;
      case AuthChangeEvent.mfaChallengeVerified:
        return AuthEvent.userUpdated;
      // ignore: deprecated_member_use
      case AuthChangeEvent.userDeleted:
        return AuthEvent.signedOut;
    }
  }

  String _passwordUpdateErrorMessage(AuthException error) {
    if (error.message.toLowerCase().contains('password')) {
      return 'La contraseña no cumple con los requisitos mínimos.';
    }
    return 'No se pudo actualizar la contraseña. Intenta de nuevo.';
  }
}
