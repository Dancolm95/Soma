import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/auth/auth_service.dart';
import 'package:soma_app/features/auth/forgot_password_screen.dart';
import 'package:soma_app/infrastructure/auth/supabase_auth_service.dart';

import '../../helpers/fake_auth_service.dart';

void main() {
  group('AuthController password recovery', () {
    late FakeAuthService authService;
    late AuthController controller;

    setUp(() {
      authService = FakeAuthService();
      controller = AuthController(authService);
    });

    tearDown(() async {
      controller.dispose();
      await authService.dispose();
    });

    test('passwordRecovery event produces AuthStatus.passwordRecovery', () {
      authService.emitPasswordRecovery(
        const SessionUser(email: 'test@example.com'),
      );

      expect(controller.status, AuthStatus.passwordRecovery);
      expect(controller.user?.email, 'test@example.com');
    });

    test('signedIn event produces AuthStatus.authenticated', () {
      authService.emit(const SessionUser(email: 'test@example.com'));

      expect(controller.status, AuthStatus.authenticated);
    });

    test('signedOut event produces AuthStatus.unauthenticated', () {
      authService.emit(null);

      expect(controller.status, AuthStatus.unauthenticated);
    });

    test('initialSession with a user is restored as authenticated', () {
      authService.emitInitialSession(
        const SessionUser(email: 'test@example.com'),
      );

      expect(controller.status, AuthStatus.authenticated);
    });

    test('initialSession without a user is unauthenticated', () {
      authService.emitInitialSession(null);

      expect(controller.status, AuthStatus.unauthenticated);
    });

    test('a normal session is not treated as recovery (no metadata used)', () {
      // A signed-in session with a user must never enter the recovery flow.
      authService.emit(const SessionUser(email: 'test@example.com'));

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.status, isNot(AuthStatus.passwordRecovery));
    });

    test('userUpdated during recovery does not leave the recovery flow', () {
      authService.emitPasswordRecovery(
        const SessionUser(email: 'test@example.com'),
      );
      authService.emitUserUpdated(const SessionUser(email: 'test@example.com'));

      expect(controller.status, AuthStatus.passwordRecovery);
    });

    test('resetPasswordForEmail delegates to service', () async {
      authService.nextResetPasswordResult =
          const PasswordRecoveryRequestAccepted();

      final result = await controller.resetPasswordForEmail('test@example.com');

      expect(result, isA<PasswordRecoveryRequestAccepted>());
    });

    test('updatePassword delegates to service', () async {
      authService.nextUpdatePasswordResult = const PasswordUpdateSuccess();

      final result = await controller.updatePassword('newpassword123');

      expect(result, isA<PasswordUpdateSuccess>());
    });

    test(
      'successful update closes the session and becomes unauthenticated',
      () async {
        authService.emitPasswordRecovery(
          const SessionUser(email: 'test@example.com'),
        );
        expect(controller.status, AuthStatus.passwordRecovery);

        authService.nextUpdatePasswordResult = const PasswordUpdateSuccess();

        final result = await controller.updatePassword('newpassword123');

        expect(result, isA<PasswordUpdateSuccess>());
        expect(authService.signOutCalled, isTrue);
        expect(controller.status, AuthStatus.unauthenticated);
      },
    );

    test('failed update keeps the recovery session open', () async {
      authService.emitPasswordRecovery(
        const SessionUser(email: 'test@example.com'),
      );

      authService.nextUpdatePasswordResult = const PasswordUpdateFailure(
        'La contraseña no cumple con los requisitos mínimos.',
      );

      final result = await controller.updatePassword('short');

      expect(result, isA<PasswordUpdateFailure>());
      expect(authService.signOutCalled, isFalse);
      expect(controller.status, AuthStatus.passwordRecovery);
    });

    test('an error on the auth stream does not crash or change state', () {
      authService.emit(const SessionUser(email: 'test@example.com'));
      expect(controller.status, AuthStatus.authenticated);

      authService.emitError(StateError('network down'));

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.user?.email, 'test@example.com');
    });
  });

  group('password recovery UI does not leak account existence', () {
    testWidgets('accepted result shows the neutral message', (tester) async {
      final service = FakeAuthService();
      final controller = AuthController(service);
      addTearDown(controller.dispose);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authController: controller)),
      );
      await tester.pumpAndSettle();

      service.nextResetPasswordResult = const PasswordRecoveryRequestAccepted();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo'),
        'user@example.com',
      );
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Si existe una cuenta asociada, recibirás instrucciones por correo.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('operational failure still shows no account existence', (
      tester,
    ) async {
      final service = FakeAuthService();
      final controller = AuthController(service);
      addTearDown(controller.dispose);
      addTearDown(service.dispose);

      await tester.pumpWidget(
        MaterialApp(home: ForgotPasswordScreen(authController: controller)),
      );
      await tester.pumpAndSettle();

      service.nextResetPasswordResult = const PasswordRecoveryFailure(
        'No se pudo procesar la solicitud. Inténtalo de nuevo.',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo'),
        'user@example.com',
      );
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo procesar la solicitud. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Si existe una cuenta asociada, recibirás instrucciones por correo.',
        ),
        findsNothing,
      );
    });
  });

  group('SupabaseAuthService.resetPasswordForEmail', () {
    test('success is a neutral accepted result', () async {
      final service = SupabaseAuthService(
        _FakeSupabaseClient(_FakeGoTrueClient()),
      );

      final result = await service.resetPasswordForEmail('test@example.com');

      expect(result, isA<PasswordRecoveryRequestAccepted>());
    });

    test('operational failure is distinct from success', () async {
      final service = SupabaseAuthService(
        _FakeSupabaseClient(
          _FakeGoTrueClient(
            error: const AuthException(
              'over request rate limit',
              statusCode: '429',
            ),
          ),
        ),
      );

      final result = await service.resetPasswordForEmail('test@example.com');

      expect(result, isA<PasswordRecoveryFailure>());
      expect(result, isNot(isA<PasswordRecoveryRequestAccepted>()));
      final failure = result as PasswordRecoveryFailure;
      expect(failure.message, isNotEmpty);
      expect(failure.message.contains('test@example.com'), isFalse);
    });
  });
}

class _FakeSupabaseClient implements SupabaseClient {
  _FakeSupabaseClient(this._auth);

  final GoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoTrueClient implements GoTrueClient {
  _FakeGoTrueClient({this.error});

  final Object? error;

  @override
  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
    String? captchaToken,
  }) async {
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
