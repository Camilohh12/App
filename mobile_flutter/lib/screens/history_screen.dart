import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final completedOrders =
        context.watch<OrderProvider>().completedOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de ventas'),
      ),
      body: completedOrders.isEmpty
          ? const Center(
        child: Text(
          'No hay ventas finalizadas',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: completedOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = completedOrders[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venta #${order.id}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  ...order.items.map(
                        (item) => Text(
                      '${item.quantity} x ${item.product.name}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: \$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Estado: Finalizada'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}