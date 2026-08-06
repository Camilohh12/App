import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

const _kDelayedThreshold = Duration(minutes: 15);

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OrderProvider>().refresh(),
    );
  }

  void logout(BuildContext context) {
    context.read<AuthProvider>().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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

  Duration elapsedSince(FoodOrder order) {
    final start = order.createdAt;
    if (start == null) return Duration.zero;
    return DateTime.now().difference(start);
  }

  bool isDelayed(FoodOrder order) {
    return order.status != OrderStatus.ready &&
        elapsedSince(order) > _kDelayedThreshold;
  }

  String formatElapsed(Duration elapsed) {
    final minutes = elapsed.inMinutes.remainder(100).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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

  Future<void> confirmCancel(BuildContext context, FoodOrder order) async {
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final errorMessage = await context.read<OrderProvider>().cancelOrder(
      order.id,
      tableProvider: context.read<TableProvider>(),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage ?? 'Orden cancelada')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.activeOrders;
    final isAdmin =
        context.watch<AuthProvider>().currentUser?.role == UserRole.admin;

    final notReady = orders
        .where((o) => o.status != OrderStatus.ready)
        .toList();
    final ready = orders.where((o) => o.status == OrderStatus.ready).length;
    final delayed = notReady.where(isDelayed).length;

    final avgMinutes = notReady.isEmpty
        ? 0
        : (notReady.fold<int>(0, (sum, o) => sum + elapsedSince(o).inMinutes) /
                  notReady.length)
              .round();

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
      body: RefreshIndicator(
        onRefresh: () => context.read<OrderProvider>().refresh(),
        child: _buildBody(
          provider,
          orders,
          isAdmin,
          notReady.length,
          ready,
          avgMinutes,
          delayed,
        ),
      ),
    );
  }

  Widget _buildBody(
    OrderProvider provider,
    List<FoodOrder> orders,
    bool isAdmin,
    int activeCount,
    int readyCount,
    int avgMinutes,
    int delayedCount,
  ) {
    if (provider.isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && orders.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(label: 'Activas', value: activeCount.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(label: 'Listas', value: readyCount.toString()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(label: 'Tiempo prom.', value: '${avgMinutes}m'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Demoradas',
                value: delayedCount.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                'No hay pedidos pendientes',
                style: TextStyle(fontSize: 18),
              ),
            ),
          )
        else
          ...orders.map((order) {
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
                                Icon(
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
                                  statusText(order.status),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
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
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
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
          }),
      ],
    );
  }
}

class _OrderActionButton extends StatefulWidget {
  final FoodOrder order;

  const _OrderActionButton({required this.order});

  @override
  State<_OrderActionButton> createState() => _OrderActionButtonState();
}

class _OrderActionButtonState extends State<_OrderActionButton> {
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
