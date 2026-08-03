import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';

import 'providers/product_provider.dart';
import 'providers/table_provider.dart';

void main() {
  runApp(const ComandaPosApp());
}

class ComandaPosApp extends StatelessWidget {
  const ComandaPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TableProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ComandaPOS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
          ),
          useMaterial3: true,
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}