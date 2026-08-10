import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import 'login_screen.dart';
import 'new_order_screen.dart';
import 'open_account_screen.dart';
import 'qr_scanner_screen.dart';
import 'tables_screen.dart';

class WaiterHomeScreen extends StatefulWidget {
  const WaiterHomeScreen({super.key});

  @override
  State<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends State<WaiterHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TableProvider>().refresh();
      context.read<OrderProvider>().refresh();
    });
  }

  void logout(BuildContext context) {
    context.read<AuthProvider>().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showOccupiedTables(BuildContext context) {
    final occupiedTables = context.read<TableProvider>().occupiedTables;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        if (occupiedTables.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No hay cuentas abiertas en este momento'),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Cuentas abiertas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...occupiedTables.map(
                (table) => ListTile(
                  leading: const Icon(Icons.table_bar, color: AppColors.tertiary),
                  title: Text('Mesa ${table.number}'),
                  subtitle: table.waiterName != null
                      ? Text('Mesero: ${table.waiterName}')
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OpenAccountScreen(tableId: table.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReadyOrders(BuildContext context) {
    final readyOrders = context
        .read<OrderProvider>()
        .readyOrders
        .where((order) => order.serviceType == ServiceType.dineIn)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        if (readyOrders.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No hay comandas listas para servir'),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Comandas listas para servir',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...readyOrders.map(
                (order) => ListTile(
                  leading: const Icon(Icons.done_all, color: AppColors.secondary),
                  title: Text('Comanda #${order.id}'),
                  subtitle: Text(
                    order.tableId != null
                        ? 'Mesa ${order.tableId} · ${order.items.length} producto${order.items.length == 1 ? '' : 's'}'
                        : '${order.items.length} producto${order.items.length == 1 ? '' : 's'}',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (order.tableId == null) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OpenAccountScreen(tableId: order.tableId!),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final tableProvider = context.watch<TableProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final occupiedCount = tableProvider.occupiedTables.length;
    final readyForTablesCount = orderProvider.readyOrders
        .where((order) => order.serviceType == ServiceType.dineIn)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ComandaPOS Bar', overflow: TextOverflow.ellipsis),
            Text(
              'Mesero: ${user?.name ?? ''}',
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
        onRefresh: () => Future.wait([
          context.read<TableProvider>().refresh(),
          context.read<OrderProvider>().refresh(),
        ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Mesas ocupadas',
                    value: occupiedCount.toString(),
                    icon: Icons.table_bar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Listas para servir',
                    value: readyForTablesCount.toString(),
                    icon: Icons.done_all,
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
                  icon: Icons.table_bar,
                  label: 'Mesas',
                  color: AppColors.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TablesScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.add_shopping_cart,
                  label: 'Nueva comanda',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewOrderScreen()),
                  ),
                ),
                _QuickAction(
                  icon: Icons.receipt_long,
                  label: 'Cuentas abiertas',
                  onTap: () => _showOccupiedTables(context),
                ),
                _QuickAction(
                  icon: Icons.done_all,
                  label: 'Comandas listas',
                  color: readyForTablesCount > 0 ? AppColors.tertiary : null,
                  onTap: () => _showReadyOrders(context),
                ),
                _QuickAction(
                  icon: Icons.qr_code_scanner,
                  label: 'Escanear mesa',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  ),
                ),
              ],
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
