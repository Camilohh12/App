import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import 'create_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<ProductProvider>().refresh(),
    );
  }

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

    final errorMessage = increase
        ? await productProvider.increaseStock(product.id, 1)
        : await productProvider.decreaseStock(product.id, 1);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage ?? 'Stock actualizado correctamente'),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context,
      Product product,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text(
            '¿Seguro que deseas eliminar "${product.name}"? '
                'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final productProvider = context.read<ProductProvider>();
    final errorMessage = await productProvider.deleteProduct(product.id);

    if (!context.mounted) return;

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${product.name}" eliminado')),
      );
      return;
    }

    // El backend rechaza el borrado si el producto tiene ventas
    // registradas (integridad referencial); ofrecemos desactivarlo
    // en su lugar en vez de dejar al admin sin salida.
    final canDeactivate =
        errorMessage.contains('ventas registradas') && product.active;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        action: canDeactivate
            ? SnackBarAction(
          label: 'Desactivar',
          onPressed: () async {
            final deactivateError = await productProvider.setActive(
              product.id,
              false,
            );

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  deactivateError ?? '"${product.name}" desactivado',
                ),
              ),
            );
          },
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateProductScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProductProvider>().refresh(),
        child: _buildBody(productProvider, products),
      ),
    );
  }

  Widget _buildBody(ProductProvider productProvider, List<Product> products) {
    if (productProvider.isLoading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productProvider.errorMessage != null && products.isEmpty) {
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
              productProvider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      );
    }

    if (products.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'No hay productos registrados',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                        style: TextStyle(
                          color: product.active
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: product.active
                          ? AppColors.secondary.withValues(alpha: 0.15)
                          : AppColors.surfaceHigh,
                      side: BorderSide.none,
                    ),
                    IconButton(
                      tooltip: 'Eliminar producto',
                      onPressed: () => _confirmDelete(context, product),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
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
                      Chip(
                        label: const Text(
                          'Agotado',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppColors.danger.withValues(
                          alpha: 0.15,
                        ),
                        side: BorderSide.none,
                      )
                    else if (isLowStock)
                      Chip(
                        label: const Text(
                          'Stock bajo',
                          style: TextStyle(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppColors.tertiary.withValues(
                          alpha: 0.15,
                        ),
                        side: BorderSide.none,
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
    );
  }
}
