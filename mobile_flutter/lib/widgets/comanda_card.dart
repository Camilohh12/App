import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../theme/app_colors.dart';

const kDelayedThreshold = Duration(minutes: 15);

Duration elapsedSince(FoodOrder order) {
  final start = order.createdAt;
  if (start == null) return Duration.zero;
  return DateTime.now().difference(start);
}

bool isDelayed(FoodOrder order) {
  return order.status != OrderStatus.ready &&
      elapsedSince(order) > kDelayedThreshold;
}

String formatElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.remainder(100).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String serviceText(FoodOrder order) {
  if (order.serviceType == ServiceType.takeaway) {
    return 'PARA LLEVAR';
  }

  return order.tableId != null ? 'MESA ${order.tableId}' : 'EN MESA';
}

Color serviceColor(FoodOrder order) {
  return order.serviceType == ServiceType.dineIn
      ? AppColors.dineIn
      : AppColors.takeaway;
}

String comandaStatusText(OrderStatus status) {
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

/// Tarjeta de una comanda para los tableros de barra/cocina. Muestra
/// solo [displayItems] (los productos de esa estación), no todo
/// `order.items` — un pedido puede tener productos de barra y cocina
/// a la vez, y cada tablero solo debe ver lo suyo.
///
/// El estado (pendiente/preparando/listo) es de la orden completa,
/// no por estación: si [hasOtherStationItems] es true, se avisa que
/// "Marcar listo" también afecta los productos de la otra estación,
/// porque el backend todavía no rastrea el avance por separado.
class ComandaCard extends StatelessWidget {
  final FoodOrder order;
  final List<OrderItem> displayItems;
  final bool hasOtherStationItems;
  final bool allowCancel;
  final Future<void> Function(BuildContext context, FoodOrder order)? onCancel;

  const ComandaCard({
    super.key,
    required this.order,
    required this.displayItems,
    this.hasOtherStationItems = false,
    this.allowCancel = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final delayed = isDelayed(order);
    final accent = serviceColor(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: delayed ? AppColors.danger : AppColors.border,
          width: delayed ? 1.5 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Orden #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (delayed)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEMORADA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatElapsed(elapsedSince(order)),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            serviceText(order),
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comandaStatusText(order.status),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ...displayItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.quantity} x ${item.product.name}'),
                            if (item.note != null && item.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  'Obs: ${item.note}',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (hasOtherStationItems) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Esta comanda también tiene productos de la otra '
                        'estación. "Marcar listo" afecta a toda la orden.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Total: \$${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    OrderActionButton(order: order),
                    if (allowCancel &&
                        onCancel != null &&
                        (order.status == OrderStatus.pending ||
                            order.status == OrderStatus.preparing)) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => onCancel!(context, order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancelar orden'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderActionButton extends StatefulWidget {
  final FoodOrder order;

  const OrderActionButton({super.key, required this.order});

  @override
  State<OrderActionButton> createState() => _OrderActionButtonState();
}

class _OrderActionButtonState extends State<OrderActionButton> {
  bool isProcessing = false;

  Future<void> updateStatus(OrderStatus status) async {
    setState(() => isProcessing = true);

    final errorMessage = await context.read<OrderProvider>().updateStatus(
      widget.order.id,
      status,
    );

    if (!mounted) return;

    setState(() => isProcessing = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return FilledButton(
          onPressed: isProcessing
              ? null
              : () => updateStatus(OrderStatus.preparing),
          child: isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Preparar'),
        );

      case OrderStatus.preparing:
        return FilledButton(
          onPressed: isProcessing
              ? null
              : () => updateStatus(OrderStatus.ready),
          style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
          child: isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Marcar listo'),
        );

      case OrderStatus.ready:
        return Container(
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
                  'Orden lista. Esperando cobro del cajero.',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        );

      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return const SizedBox.shrink();
    }
  }
}
