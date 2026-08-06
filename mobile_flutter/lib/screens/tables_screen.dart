import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/table_model.dart';
import '../providers/table_provider.dart';
import '../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final tableProvider = context.watch<TableProvider>();
    final tables = tableProvider.tables;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<TableProvider>().refresh(),
        child: _buildBody(tableProvider, tables),
      ),
    );
  }

  Widget _buildBody(TableProvider tableProvider, List<TableModel> tables) {
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        final isAvailable = table.status == TableStatus.available;

        final accent =
        isAvailable ? AppColors.secondary : AppColors.danger;

        return Card(
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
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
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
                const SizedBox(height: 4),
                Text(
                  table.qrCode,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
