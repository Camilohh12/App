import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/table_provider.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/order_service.dart';
import 'services/payment_service.dart';
import 'services/product_service.dart';
import 'services/table_service.dart';
import 'theme/app_theme.dart';

// Backend Express+Prisma corriendo en el PC (ver /backend).
// Se prueba desde un celular físico en la misma red WiFi, por eso
// se usa la IP local del PC en vez de "localhost" (el celular no
// podría resolver "localhost" como su propia PC).
// Si tu PC cambia de IP (reconexión WiFi, otra red), actualiza este
// valor con el que te devuelve "ipconfig" (adaptador Wi-Fi, IPv4).
final ApiClient _apiClient = ApiClient(
  baseUrl: 'http://192.168.190.56:3000/api',
);

void main() {
  runApp(const ComandaPosApp());
}

class ComandaPosApp extends StatelessWidget {
  const ComandaPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(_apiClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(ProductService(_apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => TableProvider(TableService(_apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(
            OrderService(_apiClient),
            PaymentService(_apiClient),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ComandaPOS Bar',
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const LoginScreen(),
      ),
    );
  }
}
