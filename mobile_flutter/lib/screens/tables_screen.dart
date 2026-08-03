import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/table_model.dart';
import '../providers/table_provider.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tables = context.watch<TableProvider>().tables;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
      ),
      body: tables.isEmpty
          ? const Center(
        child: Text(
          'No hay mesas registradas',
          style: TextStyle(fontSize: 18),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          final isAvailable = table.status == TableStatus.available;

          return Card(
            color: isAvailable
                ? Colors.green.shade50
                : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.table_bar,
                    size: 32,
                    color: isAvailable
                        ? Colors.green.shade700
                        : Colors.red.shade700,
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
                      color: isAvailable
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    table.qrCode,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
