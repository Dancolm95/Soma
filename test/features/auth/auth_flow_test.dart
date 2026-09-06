import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/auth/auth_service.dart';

import '../../helpers/fake_auth_service.dart';

void main() {
  Future<AuthController> pumpApp(
    WidgetTester tester,
    FakeAuthService service,
  ) async {
    final controller = AuthController(service);
    addTearDown(controller.dispose);
    addTearDown(service.dispose);
    await tester.pumpWidget(SomaApp(authController: controller));
    return controller;
  }

  Future<void> enterCredentials(
    WidgetTester tester, {
    String email = 'user@example.com',
    String password = 'secret123',
  }) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Correo'), email);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      password,
    );
  }

  group('auth flow', () {
    testWidgets('starts without a session and shows the sign-in form', (
      tester,
    ) async {
      final service = FakeAuthService();
      await pumpApp(tester, service);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      service.emit(null);
      await tester.pump();

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('signs in and shows the authenticated screen', (tester) async {
      final service = FakeAuthService();
      await pumpApp(tester, service);
      service.emit(null);
      await tester.pump();

      service.nextSignInResult = const AuthSuccess(
        user: SessionUser(email: 'user@example.com'),
      );

      await enterCredentials(tester);
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Sesión iniciada'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('logout removes access to the authenticated screen', (
      tester,
    ) async {
      final service = FakeAuthService();
      await pumpApp(tester, service);
      service.emit(const SessionUser(email: 'user@example.com'));
      await tester.pump();

      expect(find.text('Sesión iniciada'), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(service.signOutCalled, isTrue);
      expect(find.text('Sesión iniciada'), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('presents sign-in errors safely', (tester) async {
      final service = FakeAuthService();
      await pumpApp(tester, service);
      service.emit(null);
      await tester.pump();

      service.nextSignInResult = const AuthFailure(
        'Correo o contraseña incorrectos.',
      );

      await enterCredentials(tester);
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.textContaining('AuthException'), findsNothing);
    });

    testWidgets(
      'represents sign-up without a session as pending confirmation',
      (tester) async {
        final service = FakeAuthService();
        await pumpApp(tester, service);
        service.emit(null);
        await tester.pump();

        await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
        await tester.pump();

        service.nextSignUpResult = const EmailConfirmationRequired();

        await enterCredentials(tester);
        await tester.tap(find.text('Registrarse'));
        await tester.pumpAndSettle();

        expect(find.textContaining('confirma tu cuenta'), findsOneWidget);
        expect(find.text('Sesión iniciada'), findsNothing);
      },
    );

    testWidgets('shows the Google sign-in button', (tester) async {
      final service = FakeAuthService();
      await pumpApp(tester, service);
      service.emit(null);
      await tester.pump();

      expect(find.text('Continuar con Google'), findsOneWidget);
    });

    testWidgets('starts the Google flow without navigating', (tester) async {
      final service = FakeAuthService();
      await pumpApp(tester, service);
      service.emit(null);
      await tester.pump();

      service.nextSignInWithGoogleResult = const OAuthFlowStarted();

      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Sesión iniciada'), findsNothing);
    });

    testWidgets('presents Google OAuth errors safely', (tester) async {
      final service = FakeAuthService();
      await pumpApp(tester, service);
      service.emit(null);
      await tester.pump();

      service.nextSignInWithGoogleResult = const AuthFailure(
        'No se pudo completar el acceso con Google. Inténtalo de nuevo.',
      );

      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No se pudo completar el acceso con Google. Inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('AuthException'), findsNothing);
    });

    testWidgets(
      'password recovery update ends on the login screen via auth state',
      (tester) async {
        final service = FakeAuthService();
        final controller = AuthController(service);
        addTearDown(controller.dispose);
        addTearDown(service.dispose);
        await tester.pumpWidget(SomaApp(authController: controller));

        service.emitPasswordRecovery(
          const SessionUser(email: 'user@example.com'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Actualizar contraseña'), findsOneWidget);

        service.nextUpdatePasswordResult = const PasswordUpdateSuccess();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nueva contraseña'),
          'newsecret123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar contraseña'),
          'newsecret123',
        );
        await tester.tap(find.text('Actualizar contraseña'));
        await tester.pumpAndSettle();

        expect(service.signOutCalled, isTrue);
        expect(controller.status, AuthStatus.unauthenticated);
        expect(find.text('Actualizar contraseña'), findsNothing);
        expect(find.text('Entrar'), findsOneWidget);
      },
    );

    testWidgets('recovery link pops the forgot-password screen automatically', (
      tester,
    ) async {
      final service = FakeAuthService();
      final controller = AuthController(service);
      addTearDown(controller.dispose);
      addTearDown(service.dispose);
      await tester.pumpWidget(SomaApp(authController: controller));

      service.emit(null);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Olvidé mi contraseña'));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar contraseña'), findsOneWidget);

      service.emitPasswordRecovery(
        const SessionUser(email: 'user@example.com'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recuperar contraseña'), findsNothing);
      expect(find.text('Actualizar contraseña'), findsOneWidget);
    });
  });
}
