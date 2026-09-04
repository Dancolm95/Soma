import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soma_app/infrastructure/auth/auth_error_messages.dart';

void main() {
  group('signInErrorMessage', () {
    test('asks for confirmation when email is not confirmed', () {
      final error = AuthException(
        'Email not confirmed',
        code: ErrorCode.emailNotConfirmed.code,
      );

      expect(signInErrorMessage(error), contains('Confirma tu correo'));
    });

    test('collapses every other failure to a generic message', () {
      final error = AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );

      expect(signInErrorMessage(error), 'Correo o contraseña incorrectos.');
    });
  });

  group('signUpErrorMessage', () {
    test('reports an existing account', () {
      final error = AuthException(
        'User already registered',
        code: ErrorCode.userAlreadyExists.code,
      );

      expect(signUpErrorMessage(error), contains('Ya existe una cuenta'));
    });

    test('reports a weak password with the minimum length', () {
      final error = AuthException(
        'Password should be at least 6 characters',
        code: ErrorCode.weakPassword.code,
      );

      expect(signUpErrorMessage(error), contains('al menos 6 caracteres'));
    });

    test('reports an invalid email', () {
      final error = AuthException(
        'Unable to validate email address',
        code: ErrorCode.validationFailed.code,
      );

      expect(signUpErrorMessage(error), contains('Revisa el correo'));
    });

    test('falls back to a generic message for unknown codes', () {
      final error = AuthException('Something failed', code: 'unknown_code');

      expect(
        signUpErrorMessage(error),
        'No se pudo completar el registro. Inténtalo de nuevo.',
      );
    });
  });
}
