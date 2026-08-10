import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/main.dart';

void main() {
  testWidgets('La app inicia mostrando la pantalla de login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ComandaPosApp());

    expect(find.text('ComandaPOS Bar'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // LoginScreen dispara un chequeo de conexión (Dio) en initState.
    // En el entorno de pruebas no hay servidor real, así que se
    // avanza el reloj virtual más allá del connectTimeout para que
    // esa solicitud se resuelva (con error) y no deje un Timer
    // pendiente al terminar el test.
    await tester.pump(const Duration(seconds: 11));
  });
}
