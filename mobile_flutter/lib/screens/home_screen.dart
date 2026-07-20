import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../widgets/summary_card.dart';
import 'history_screen.dart';
import 'kitchen_screen.dart';
import 'new_order_screen.dart';
import 'products_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ComandaPOS'),
            Text(
              'Punto de venta para negocios de comida',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewOrderScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Panel principal',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: 'Ventas del día',
            value:
            '\$${orderProvider.dailySales.toStringAsFixed(2)}',
          ),
          SummaryCard(
            title: 'Órdenes pendientes',
            value: orderProvider.pendingOrders.toString(),
          ),
          const SummaryCard(
            title: 'Productos disponibles',
            value: '4',
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductsScreen(),
                ),
              );
            },
            child: const Text('Ver productos'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KitchenScreen(),
                ),
              );
            },
            child: const Text('Pedidos de cocina'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
            child: const Text('Historial de ventas'),
          ),
        ],
      ),
    );
  }
}