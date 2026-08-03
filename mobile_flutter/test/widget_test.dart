import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/main.dart';

void main() {
  testWidgets('La app inicia mostrando la pantalla de login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ComandaPosApp());

    expect(find.text('ComandaPOS'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
