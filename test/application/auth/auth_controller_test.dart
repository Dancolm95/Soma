import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/auth/auth_controller.dart';
import 'package:soma_app/application/auth/auth_service.dart';

import '../../helpers/fake_auth_service.dart';

void main() {
  group('AuthController', () {
    test('starts in the initializing state', () {
      final service = FakeAuthService();
      final controller = AuthController(service);

      expect(controller.status, AuthStatus.initializing);
      expect(controller.user, isNull);

      controller.dispose();
    });

    test('becomes unauthenticated when no session is emitted', () {
      final service = FakeAuthService();
      final controller = AuthController(service);

      service.emit(null);

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.user, isNull);

      controller.dispose();
    });

    test('becomes authenticated when a session is emitted', () {
      final service = FakeAuthService();
      final controller = AuthController(service);

      service.emit(const SessionUser(email: 'a@b.com'));

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.user?.email, 'a@b.com');

      controller.dispose();
    });

    test('transitions back to unauthenticated after sign-out', () {
      final service = FakeAuthService();
      final controller = AuthController(service);

      service.emit(const SessionUser(email: 'a@b.com'));
      service.emit(null);

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.user, isNull);

      controller.dispose();
    });

    test('signOut delegates to the service', () async {
      final service = FakeAuthService();
      final controller = AuthController(service);

      await controller.signOut();

      expect(service.signOutCalled, isTrue);

      controller.dispose();
    });

    test('signInWithGoogle delegates to the service', () async {
      final service = FakeAuthService();
      final controller = AuthController(service);

      service.nextSignInWithGoogleResult = const OAuthFlowStarted();

      final result = await controller.signInWithGoogle();

      expect(result, isA<OAuthFlowStarted>());

      controller.dispose();
    });
  });
}
