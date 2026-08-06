import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'kitchen_screen.dart';
import 'reports_screen.dart';

const _kPollInterval = Duration(seconds: 8);

/// Contenedor con navegación inferior persistente para el rol
/// administrador. Cada pestaña conserva su propio Scaffold/AppBar;
/// el shell solo agrega la barra inferior y mantiene el estado de
/// cada pantalla viva mientras se navega entre pestañas.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int currentIndex = 0;
  Timer? _pollTimer;

  static const _tabs = [
    HomeScreen(),
    KitchenScreen(),
    InventoryScreen(),
    HistoryScreen(),
    ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Refresca órdenes y productos en segundo plano para que Inicio,
    // Cocina, Inventario e Historial reflejen pedidos nuevos, cambios
    // de estado y ajustes de stock sin pull-to-refresh manual.
    _pollTimer = Timer.periodic(_kPollInterval, (_) {
      if (!mounted) return;
      context.read<OrderProvider>().refresh();
      context.read<ProductProvider>().refresh();
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
            icon: Icon(Icons.soup_kitchen_outlined),
            activeIcon: Icon(Icons.soup_kitchen),
            label: 'Cocina',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
