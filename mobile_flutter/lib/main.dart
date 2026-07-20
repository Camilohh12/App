import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/order_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ComandaPosApp());
}

class ComandaPosApp extends StatelessWidget {
  const ComandaPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ComandaPOS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}