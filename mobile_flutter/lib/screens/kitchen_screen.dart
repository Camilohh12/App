import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/comanda_card.dart';
import '../widgets/stat_card.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

List<OrderItem> kitchenItemsOf(FoodOrder order) {
  return order.items
      .where((item) => item.product.preparationArea == PreparationArea.kitchen)
      .toList();
}

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
    final isAdmin =
        context.watch<AuthProvider>().currentUser?.role == UserRole.admin;

    // Solo comandas que tienen al menos un producto de cocina.
    final orders = provider.activeOrders
        .where((order) => kitchenItemsOf(order).isNotEmpty)
        .toList();

    final notReady = orders.where((o) => o.status != OrderStatus.ready).toList();
    final ready = orders.where((o) => o.status == OrderStatus.ready).length;
    final delayed = notReady.where(isDelayed).length;

    final avgMinutes = notReady.isEmpty
        ? 0
        : (notReady.fold<int>(0, (sum, o) => sum + elapsedSince(o).inMinutes) /
                  notReady.length)
              .round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comandas de cocina'),
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
                'No hay comandas de cocina pendientes',
                style: TextStyle(fontSize: 18),
              ),
            ),
          )
        else
          ...orders.map(
            (order) => ComandaCard(
              order: order,
              displayItems: kitchenItemsOf(order),
              hasOtherStationItems:
                  kitchenItemsOf(order).length != order.items.length,
              allowCancel: isAdmin,
              onCancel: confirmCancel,
            ),
          ),
      ],
    );
  }
}
