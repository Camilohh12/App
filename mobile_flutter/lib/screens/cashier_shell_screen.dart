import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import 'cashier_home_screen.dart';
import 'history_screen.dart';
import 'new_order_screen.dart';
import 'payment_screen.dart';
import 'tables_screen.dart';

const _kPollInterval = Duration(seconds: 8);

/// Contenedor con navegación inferior persistente para el rol
/// cajero. Ver AdminShellScreen para el criterio de diseño.
class CashierShellScreen extends StatefulWidget {
  const CashierShellScreen({super.key});

  @override
  State<CashierShellScreen> createState() => _CashierShellScreenState();
}

class _CashierShellScreenState extends State<CashierShellScreen> {
  int currentIndex = 0;
  Timer? _pollTimer;

  static const _tabs = [
    CashierHomeScreen(),
    NewOrderScreen(),
    TablesScreen(),
    PaymentScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Refresca órdenes y mesas en segundo plano para que Inicio,
    // Mesas, Cobrar e Historial reflejen pedidos nuevos, cambios de
    // estado y disponibilidad de mesas sin pull-to-refresh manual.
    _pollTimer = Timer.periodic(_kPollInterval, (_) {
      if (!mounted) return;
      context.read<OrderProvider>().refresh();
      context.read<TableProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart_outlined),
            activeIcon: Icon(Icons.add_shopping_cart),
            label: 'Nueva orden',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_bar_outlined),
            activeIcon: Icon(Icons.table_bar),
            label: 'Mesas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Cobrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
