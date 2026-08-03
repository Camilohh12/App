import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';

import '../models/user.dart';
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

  String serviceText(FoodOrder order) {
    if (order.serviceType == ServiceType.takeaway) {
      return 'Para llevar';
    }

    return order.tableId != null
        ? 'Mesa ${order.tableId}'
        : 'En mesa';
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
      case OrderStatus.cancelled:
        return 'Cancelada';
    }
  }

  Future<void> confirmCancel(
      BuildContext context,
      FoodOrder order,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar orden'),
          content: Text(
            '¿Seguro que deseas cancelar la orden #${order.id}? '
                'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final success = context.read<OrderProvider>().cancelOrder(
      order.id,
      tableProvider: context.read<TableProvider>(),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Orden cancelada'
              : 'No fue posible cancelar la orden',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.activeOrders;
    final isAdmin =
        context.watch<AuthProvider>().currentUser?.role == UserRole.admin;

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
                  Text(serviceText(order)),
                  const Divider(),
                  ...order.items.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity} x ${item.product.name}',
                          ),
                          if (item.note != null &&
                              item.note!.isNotEmpty)
                            Padding(
                              padding:
                              const EdgeInsets.only(left: 12),
                              child: Text(
                                'Obs: ${item.note}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
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
                  if (isAdmin &&
                      (order.status == OrderStatus.pending ||
                          order.status == OrderStatus.preparing)) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => confirmCancel(context, order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size.fromHeight(45),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar orden'),
                    ),
                  ],
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
      case OrderStatus.cancelled:
        return const SizedBox.shrink();
    }
  }
}