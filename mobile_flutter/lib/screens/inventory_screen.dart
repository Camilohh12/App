import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  Future<void> _confirmAdjustment(
      BuildContext context, {
        required Product product,
        required bool increase,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            increase ? 'Aumentar existencias' : 'Disminuir existencias',
          ),
          content: Text(
            increase
                ? '¿Aumentar en 1 el stock de "${product.name}"?'
                : '¿Disminuir en 1 el stock de "${product.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final productProvider = context.read<ProductProvider>();

    final success = increase
        ? productProvider.increaseStock(product.id, 1)
        : productProvider.decreaseStock(product.id, 1);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Stock actualizado correctamente'
              : 'No fue posible actualizar el stock',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
      ),
      body: products.isEmpty
          ? const Center(
        child: Text(
          'No hay productos registrados',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          final isOutOfStock = product.stock == 0;
          final isLowStock = !isOutOfStock && product.stock <= 5;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(product.category),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          product.active ? 'Activo' : 'Inactivo',
                        ),
                        backgroundColor: product.active
                            ? Colors.green.shade100
                            : Colors.grey.shade300,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      if (isOutOfStock)
                        const Chip(
                          label: Text('Agotado'),
                          backgroundColor: Color(0xFFFFCDD2),
                        )
                      else if (isLowStock)
                        const Chip(
                          label: Text('Stock bajo'),
                          backgroundColor: Color(0xFFFFE0B2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Existencias',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Disminuir',
                            onPressed: product.stock > 0
                                ? () => _confirmAdjustment(
                              context,
                              product: product,
                              increase: false,
                            )
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              product.stock.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge,
                            ),
                          ),
                          IconButton.filled(
                            tooltip: 'Aumentar',
                            onPressed: () => _confirmAdjustment(
                              context,
                              product: product,
                              increase: true,
                            ),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
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
