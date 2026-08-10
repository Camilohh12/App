import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import 'bar_screen.dart';
import 'create_user_screen.dart';
import 'history_screen.dart';
import 'inventory_screen.dart';
import 'kitchen_screen.dart';
import 'new_order_screen.dart';
import 'reports_screen.dart';
import 'sensors_screen.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().refresh();
      context.read<ProductProvider>().refresh();
    });
  }

  String paymentMethodText(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case null:
        return 'Sin registrar';
    }
  }

  IconData paymentMethodIcon(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.transfer:
        return Icons.account_balance;
      case null:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final productProvider = context.watch<ProductProvider>();
    final lowStockCount = productProvider.lowStockProducts.length;

    final recentTransactions = orderProvider.completedOrders.reversed
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ComandaPOS Bar', overflow: TextOverflow.ellipsis),
            Text(
              'Panel de administrador',
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Crear usuario',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateUserScreen()),
            ),
            icon: const Icon(Icons.person_add_alt),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              context.read<AuthProvider>().logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                    (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          context.read<OrderProvider>().refresh(),
          context.read<ProductProvider>().refresh(),
        ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HeroStatCard(
              label: 'Ventas de hoy',
              value: '\$${orderProvider.dailySales.toStringAsFixed(2)}',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Órdenes activas',
                    value: orderProvider.pendingOrders.toString(),
                    icon: Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Stock bajo',
                    value: lowStockCount.toString(),
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Accesos rápidos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _QuickAction(
                  icon: Icons.add_shopping_cart,
                  label: 'Nueva orden',
                  color: AppColors.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewOrderScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.inventory_2,
                  label: 'Inventario',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.soup_kitchen,
                  label: 'Cocina',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KitchenScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.local_bar,
                  label: 'Barra',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BarScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.bar_chart,
                  label: 'Reportes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.my_location,
                  label: 'Sensor GPS',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SensorsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transacciones recientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (recentTransactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Todavía no hay ventas registradas hoy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...recentTransactions.map(
                    (order) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.secondary.withValues(
                          alpha: 0.15,
                        ),
                        child: Icon(
                          paymentMethodIcon(order.paymentMethod),
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Orden #${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              paymentMethodText(order.paymentMethod),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.surfaceHigh;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color != null ? accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
