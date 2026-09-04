import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/auth/auth_controller.dart';

import 'helpers/fake_auth_service.dart';

void main() {
  testWidgets('SomaApp boots into the auth flow', (tester) async {
    final service = FakeAuthService();
    final controller = AuthController(service);
    addTearDown(controller.dispose);
    addTearDown(service.dispose);

    await tester.pumpWidget(SomaApp(authController: controller));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
