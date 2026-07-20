import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  String statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.preparing:
        return 'En preparación';
      case OrderStatus.ready:
        return 'Listo';
      case OrderStatus.completed:
        return 'Finalizada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.activeOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos de cocina'),
      ),
      body: orders.isEmpty
          ? const Center(
        child: Text(
          'No hay pedidos pendientes',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orden #${order.id}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Estado: ${statusText(order.status)}'),
                  const Divider(),
                  ...order.items.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${item.quantity} x ${item.product.name}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: \$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OrderActionButton(order: order),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  final FoodOrder order;

  const _OrderActionButton({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();

    switch (order.status) {
      case OrderStatus.pending:
        return FilledButton(
          onPressed: () {
            provider.updateStatus(
              order.id,
              OrderStatus.preparing,
            );
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(45),
          ),
          child: const Text('Preparar'),
        );

      case OrderStatus.preparing:
        return FilledButton(
          onPressed: () {
            provider.updateStatus(
              order.id,
              OrderStatus.ready,
            );
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(45),
          ),
          child: const Text('Marcar listo'),
        );

      case OrderStatus.ready:
        return FilledButton(
          onPressed: () {
            provider.updateStatus(
              order.id,
              OrderStatus.completed,
            );
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(45),
          ),
          child: const Text('Finalizar venta'),
        );

      case OrderStatus.completed:
        return const SizedBox.shrink();
    }
  }
}