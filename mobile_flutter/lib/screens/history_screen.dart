import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String paymentMethodText(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case null:
        return 'No registrado';
    }
  }

  String serviceText(FoodOrder order) {
    if (order.serviceType == ServiceType.takeaway) {
      return 'Para llevar';
    }

    return order.tableId != null
        ? 'Mesa ${order.tableId}'
        : 'En mesa';
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Sin fecha';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

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
        separatorBuilder: (_, __) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = completedOrders[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
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

                  const SizedBox(height: 4),

                  Text(
                    'Fecha: ${formatDate(order.completedAt)}',
                  ),

                  const SizedBox(height: 4),

                  Text(serviceText(order)),

                  const Divider(),

                  ...order.items.map(
                        (item) => Padding(
                      padding:
                      const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity} x '
                                '${item.product.name}',
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

                  const SizedBox(height: 12),

                  Text(
                    'Total: '
                        '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Método de pago: '
                        '${paymentMethodText(order.paymentMethod)}',
                  ),

                  if (order.paymentMethod ==
                      PaymentMethod.cash) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Monto recibido: '
                          '\$${(order.amountReceived ?? 0).toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cambio: '
                          '\$${(order.change ?? 0).toStringAsFixed(2)}',
                    ),
                  ],

                  const SizedBox(height: 6),

                  const Text(
                    'Estado: Finalizada',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}