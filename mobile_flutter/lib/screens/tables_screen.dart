import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/table_model.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import '../theme/app_colors.dart';
import 'new_order_screen.dart';
import 'open_account_screen.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<TableProvider>().refresh(),
    );
  }

  FoodOrder? _activeOrderForTable(OrderProvider orderProvider, int tableId) {
    for (final order in orderProvider.activeOrders) {
      if (order.tableId == tableId) return order;
    }
    return null;
  }

  Future<void> _openTable(TableModel table) async {
    final waiterController = TextEditingController();

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Abrir Mesa ${table.number}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Deseas abrir esta mesa para tomar una comanda?'),
              const SizedBox(height: 16),
              TextField(
                controller: waiterController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Mesero (opcional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Abrir mesa'),
            ),
          ],
        );
      },
    );

    final waiterName = waiterController.text;
    waiterController.dispose();

    if (shouldOpen != true || !mounted) return;

    if (waiterName.trim().isNotEmpty) {
      context.read<TableProvider>().assignWaiter(table.id, waiterName);
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewOrderScreen(
          initialServiceType: ServiceType.dineIn,
          initialTableId: table.id,
        ),
      ),
    );
  }

  void _viewOccupiedTable(TableModel table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpenAccountScreen(tableId: table.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableProvider = context.watch<TableProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final tables = tableProvider.tables;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TableProvider>().refresh(),
        child: _buildBody(tableProvider, orderProvider, tables),
      ),
    );
  }

  Widget _buildBody(
    TableProvider tableProvider,
    OrderProvider orderProvider,
    List<TableModel> tables,
  ) {
    if (tableProvider.isLoading && tables.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tableProvider.errorMessage != null && tables.isEmpty) {
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
              tableProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }

    if (tables.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No hay mesas registradas',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final isAvailable = table.status == TableStatus.available;
        final activeOrder = isAvailable
            ? null
            : _activeOrderForTable(orderProvider, table.id);

        // Disponible = éxito (verde), ocupada = advertencia (ámbar).
        final accent = isAvailable ? AppColors.secondary : AppColors.tertiary;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => isAvailable
              ? _openTable(table)
              : _viewOccupiedTable(table),
          child: Card(
            color: accent.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: accent.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_bar,
                    size: 32,
                    color: accent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mesa ${table.number}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAvailable ? 'Disponible' : 'Ocupada',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (table.waiterName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      table.waiterName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (activeOrder != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\$${activeOrder.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
