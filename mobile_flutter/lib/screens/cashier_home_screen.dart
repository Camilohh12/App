import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import 'login_screen.dart';
import 'new_order_screen.dart';
import 'payment_screen.dart';
import 'qr_scanner_screen.dart';
import 'sensors_screen.dart';
import 'tables_screen.dart';

class CashierHomeScreen extends StatefulWidget {
  const CashierHomeScreen({super.key});

  @override
  State<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends State<CashierHomeScreen> {
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
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final orderProvider = context.watch<OrderProvider>();
    final readyCount = orderProvider.readyOrders.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ComandaPOS Bar', overflow: TextOverflow.ellipsis),
            Text(
              'Cajero: ${user?.name ?? ''}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
                    label: 'Listas para cobrar',
                    value: readyCount.toString(),
                    icon: Icons.payments,
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
                  icon: Icons.table_bar,
                  label: 'Mesas',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TablesScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.qr_code_scanner,
                  label: 'Escanear mesa',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QrScannerScreen(),
                    ),
                  ),
                ),
                _QuickAction(
                  icon: Icons.payments,
                  label: 'Cobrar órdenes',
                  color: readyCount > 0 ? AppColors.tertiary : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentScreen()),
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
            if (readyCount > 0) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: AppColors.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        readyCount == 1
                            ? 'Hay 1 orden lista para cobrar'
                            : 'Hay $readyCount órdenes listas para cobrar',
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color != null ? Colors.white : AppColors.textPrimary,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color != null ? Colors.white : AppColors.textPrimary,
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
