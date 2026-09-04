/// Minimum password length enforced client-side as a first pass.
///
/// This matches the local Supabase configuration (`minimum_password_length`).
/// The Supabase Auth server remains the authoritative validator.
const kMinPasswordLength = 6;

/// Minimal authenticated identity exposed to the application.
///
/// Only the fields the UI actually needs are exposed. Tokens and internal
/// session data are intentionally not part of this type.
class SessionUser {
  const SessionUser({required this.email});

  final String? email;
}

/// Outcome of a sign-in or sign-up attempt.
sealed class AuthResult {
  const AuthResult();
}

/// Authentication completed and a session is now active.
class AuthSuccess extends AuthResult {
  const AuthSuccess({required this.user});

  final SessionUser user;
}

/// Sign-up completed but the account still needs email confirmation,
/// so no session was created yet.
class EmailConfirmationRequired extends AuthResult {
  const EmailConfirmationRequired();
}

/// Authentication failed. [message] is safe to show to the user.
class AuthFailure extends AuthResult {
  const AuthFailure(this.message);

  final String message;
}

/// Boundary for Supabase Auth access.
///
/// This is the only place that talks to Supabase Auth. UI and app state depend
/// on this contract, not on Supabase types, so they can be tested with doubles.
abstract class AuthService {
  /// Emits the current authenticated identity (or null) whenever the session
  /// changes, including the session restored at startup.
  Stream<SessionUser?> authStateChanges();

  Future<AuthResult> signUp({required String email, required String password});

  Future<AuthResult> signIn({required String email, required String password});

  Future<void> signOut();
}
