import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import '../theme/app_colors.dart';
import 'new_order_screen.dart';

/// Cuenta abierta de una mesa ocupada: productos acumulados, total y
/// la posibilidad de agregar otra ronda o solicitar la cuenta para
/// cobro. "Agregar otra ronda" depende de un endpoint del backend que
/// todavía no existe (ver docs/endpoints.md) — si falla, se lo dice
/// tal cual al usuario en vez de fingir que funcionó.
class OpenAccountScreen extends StatefulWidget {
  final int tableId;

  const OpenAccountScreen({super.key, required this.tableId});

  @override
  State<OpenAccountScreen> createState() => _OpenAccountScreenState();
}

class _OpenAccountScreenState extends State<OpenAccountScreen> {
  bool isRequestingBill = false;

  String statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.preparing:
        return 'En preparación';
      case OrderStatus.ready:
        return 'Lista · esperando cobro';
      case OrderStatus.completed:
        return 'Finalizada';
      case OrderStatus.cancelled:
        return 'Cancelada';
    }
  }

  Future<void> _addRound(int orderId, int tableId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewOrderScreen(
          addToOrderId: orderId,
          initialServiceType: ServiceType.dineIn,
          initialTableId: tableId,
        ),
      ),
    );
  }

  Future<void> _requestBill(int orderId) async {
    setState(() => isRequestingBill = true);

    final errorMessage = await context.read<OrderProvider>().updateStatus(
          orderId,
          OrderStatus.ready,
        );

    if (!mounted) return;

    setState(() => isRequestingBill = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage ?? 'Cuenta solicitada. Lista para cobro.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableProvider = context.watch<TableProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final table = tableProvider.findById(widget.tableId);

    FoodOrder? activeOrder;
    for (final order in orderProvider.activeOrders) {
      if (order.tableId == widget.tableId) {
        activeOrder = order;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          table != null ? 'Mesa ${table.number}' : 'Cuenta abierta',
        ),
      ),
      body: table == null || activeOrder == null
          ? _EmptyAccountState(tableNumber: table?.number)
          : _buildAccount(table.waiterName, activeOrder),
    );
  }

  Widget _buildAccount(String? waiterName, FoodOrder order) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (waiterName != null) ...[
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Mesero: $waiterName',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            const Icon(Icons.receipt_long, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Comanda #${order.id} · ${statusText(order.status)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Productos acumulados',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...order.items.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity} x ${item.product.name}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (item.note != null && item.note!.isNotEmpty)
                        Text(
                          'Obs: ${item.note}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total acumulado', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _addRound(order.id, widget.tableId),
          icon: const Icon(Icons.add),
          label: const Text('Agregar otra ronda'),
        ),
        const SizedBox(height: 12),
        if (order.status == OrderStatus.ready)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cuenta solicitada. Esperando cobro del cajero.',
                    style: TextStyle(color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: isRequestingBill ? null : () => _requestBill(order.id),
            icon: isRequestingBill
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.request_page_outlined),
            label: const Text('Solicitar cuenta'),
          ),
      ],
    );
  }
}

class _EmptyAccountState extends StatelessWidget {
  final int? tableNumber;

  const _EmptyAccountState({this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.table_bar, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(
          tableNumber != null
              ? 'La Mesa $tableNumber ya no tiene una cuenta abierta.'
              : 'Esta mesa ya no tiene una cuenta abierta.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
