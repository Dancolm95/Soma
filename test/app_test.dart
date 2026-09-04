import 'package:flutter_test/flutter_test.dart';
import 'package:soma_app/application/app.dart';
import 'package:soma_app/application/configuration/app_environment.dart';

void main() {
  testWidgets('SomaApp boots and renders the launch screen', (tester) async {
    const config = AppConfig(environment: AppEnvironment.development);

    await tester.pumpWidget(const SomaApp(config: config));

    expect(find.text('Soma'), findsOneWidget);
    expect(find.text('environment: development'), findsOneWidget);
  });
}
