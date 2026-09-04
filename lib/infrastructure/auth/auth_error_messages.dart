import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soma_app/application/auth/auth_service.dart';

/// Maps Supabase Auth errors to user-safe messages for sign-in.
///
/// Every failure except "email not confirmed" collapses to a single generic
/// message so account existence is never revealed.
String signInErrorMessage(AuthException error) {
  if (error.code == ErrorCode.emailNotConfirmed.code) {
    return 'Confirma tu correo antes de iniciar sesión.';
  }
  return 'Correo o contraseña incorrectos.';
}

/// Maps Supabase Auth errors to user-safe messages for sign-up.
String signUpErrorMessage(AuthException error) {
  final code = error.code;
  if (code == ErrorCode.userAlreadyExists.code ||
      code == ErrorCode.emailExists.code) {
    return 'Ya existe una cuenta con este correo. Inicia sesión.';
  }
  if (code == ErrorCode.weakPassword.code) {
    return 'La contraseña debe tener al menos $kMinPasswordLength caracteres.';
  }
  if (code == ErrorCode.validationFailed.code) {
    return 'Revisa el correo introducido.';
  }
  return 'No se pudo completar el registro. Inténtalo de nuevo.';
}
