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

/// The OAuth flow was launched successfully.
///
/// The resulting session (or its absence, if the user cancels) arrives
/// asynchronously via [AuthService.authStateChanges].
class OAuthFlowStarted extends AuthResult {
  const OAuthFlowStarted();
}

/// Auth lifecycle event observed by the application.
///
/// Mirrors the provider's events without exposing provider-specific types, so
/// features/ never depend on Supabase. [passwordRecovery] is the only signal
/// used to enter the recovery flow; it is never inferred from session metadata.
enum AuthEvent {
  /// Session restored at startup (or absent if the user never signed in).
  initialSession,

  /// A password recovery link established a temporary recovery session.
  passwordRecovery,

  /// A normal sign-in completed.
  signedIn,

  /// The user was signed out.
  signedOut,

  /// The session was refreshed; the user remains signed in.
  tokenRefreshed,

  /// The user record was updated (e.g. password change during recovery).
  userUpdated,
}

/// Snapshot of authentication state emitted by [AuthService.authStateChanges].
class AuthStateChange {
  const AuthStateChange(this.event, this.user);

  final AuthEvent event;

  /// The authenticated identity, or null when the event implies no session.
  final SessionUser? user;
}

/// Outcome of a password recovery request.
sealed class PasswordRecoveryResult {
  const PasswordRecoveryResult();
}

/// Recovery request accepted.
///
/// The result is neutral on purpose: Supabase returns the same outcome whether
/// or not the account exists, so this value must never reveal account existence.
class PasswordRecoveryRequestAccepted extends PasswordRecoveryResult {
  const PasswordRecoveryRequestAccepted();
}

/// Recovery request could not be processed due to an operational error
/// (network, rate limit, misconfiguration).
///
/// [message] is safe to show to the user and never contains the email, tokens
/// or credentials.
class PasswordRecoveryFailure extends PasswordRecoveryResult {
  const PasswordRecoveryFailure(this.message);

  final String message;
}

/// Outcome of a password update attempt.
sealed class PasswordUpdateResult {
  const PasswordUpdateResult();
}

/// Password updated successfully.
class PasswordUpdateSuccess extends PasswordUpdateResult {
  const PasswordUpdateSuccess();
}

/// Password update failed.
class PasswordUpdateFailure extends PasswordUpdateResult {
  const PasswordUpdateFailure(this.message);

  final String message;
}

/// Boundary for Supabase Auth access.
///
/// This is the only place that talks to Supabase Auth. UI and app state depend
/// on this contract, not on Supabase types, so they can be tested with doubles.
abstract class AuthService {
  /// Emits authentication state changes, including the session restored at
  /// startup and the [AuthEvent.passwordRecovery] event.
  Stream<AuthStateChange> authStateChanges();

  Future<AuthResult> signUp({required String email, required String password});

  Future<AuthResult> signIn({required String email, required String password});

  /// Starts a Google OAuth flow. The session, if one is established, is
  /// delivered via [authStateChanges]; this method only reports whether the
  /// flow could be started.
  Future<AuthResult> signInWithGoogle();

  /// Requests a password recovery email for the given address.
  ///
  /// The accepted result is always neutral to avoid revealing whether the
  /// account exists. Operational failures (network, rate limit) are reported
  /// separately so they can be diagnosed without leaking the email.
  Future<PasswordRecoveryResult> resetPasswordForEmail(String email);

  /// Updates the password for the current authenticated session.
  ///
  /// This is intended for use during a password recovery flow.
  Future<PasswordUpdateResult> updatePassword(String newPassword);

  Future<void> signOut();
}
