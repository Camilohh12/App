import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/comanda_card.dart';
import '../widgets/stat_card.dart';
import 'login_screen.dart';

List<OrderItem> barItemsOf(FoodOrder order) {
  return order.items
      .where((item) => item.product.preparationArea == PreparationArea.bar)
      .toList();
}

/// Tablero de barra: solo muestra los productos de barra de cada
/// comanda (bebidas, cócteles, etc.). A diferencia de Cocina, no
/// permite cobrar ni cancelar — esas acciones son de cajero/admin.
class BarScreen extends StatefulWidget {
  const BarScreen({super.key});

  @override
  State<BarScreen> createState() => _BarScreenState();
}

class _BarScreenState extends State<BarScreen> {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    // Solo comandas que tienen al menos un producto de barra.
    final orders = provider.activeOrders
        .where((order) => barItemsOf(order).isNotEmpty)
        .toList();

    final notReady = orders.where((o) => o.status != OrderStatus.ready).toList();
    final ready = orders.where((o) => o.status == OrderStatus.ready).length;
    final delayed = notReady.where(isDelayed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comandas de barra'),
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
        child: _buildBody(provider, orders, notReady.length, ready, delayed),
      ),
    );
  }

  Widget _buildBody(
    OrderProvider provider,
    List<FoodOrder> orders,
    int activeCount,
    int readyCount,
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
                'No hay comandas de barra pendientes',
                style: TextStyle(fontSize: 18),
              ),
            ),
          )
        else
          ...orders.map(
            (order) => ComandaCard(
              order: order,
              displayItems: barItemsOf(order),
              hasOtherStationItems:
                  barItemsOf(order).length != order.items.length,
            ),
          ),
      ],
    );
  }
}
