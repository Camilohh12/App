import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'new_order_screen.dart';
import 'payment_screen.dart';
import 'products_screen.dart';

class CashierHomeScreen extends StatelessWidget {
  const CashierHomeScreen({super.key});

  void logout(BuildContext context) {
    context.read<AuthProvider>().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ComandaPOS'),
            Text(
              'Cajero: ${user?.name ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewOrderScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva orden'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Panel del cajero',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NewOrderScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Nueva orden'),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.fastfood),
            label: const Text('Consultar productos'),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentScreen(),
                ),
              );
            },
            icon: const Icon(Icons.payments),
            label: const Text('Cobrar órdenes'),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('Historial de ventas'),
          ),
        ],
      ),
    );
  }
}