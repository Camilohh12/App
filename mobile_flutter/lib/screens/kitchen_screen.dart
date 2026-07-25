import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

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
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
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
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Orden lista. Esperando cobro del cajero.',
                  ),
                ),
              ],
            ),
          ),
        );

      case OrderStatus.completed:
        return const SizedBox.shrink();
    }
  }
}