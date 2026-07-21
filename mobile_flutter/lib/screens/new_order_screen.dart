import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import 'products_screen.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final Map<int, int> quantities = {};

  int getQuantity(int productId) {
    return quantities[productId] ?? 0;
  }

  void increaseQuantity(int productId) {
    setState(() {
      quantities[productId] = getQuantity(productId) + 1;
    });
  }

  void decreaseQuantity(int productId) {
    final currentQuantity = getQuantity(productId);

    if (currentQuantity <= 1) {
      setState(() {
        quantities.remove(productId);
      });
      return;
    }

    setState(() {
      quantities[productId] = currentQuantity - 1;
    });
  }

  double get total {
    return availableProducts.fold(0, (sum, product) {
      return sum + product.price * getQuantity(product.id);
    });
  }

  void confirmOrder() {
    final selectedItems = availableProducts
        .where((product) => getQuantity(product.id) > 0)
        .map(
          (product) => OrderItem(
        product: product,
        quantity: getQuantity(product.id),
      ),
    )
        .toList();

    if (selectedItems.isEmpty) {
      return;
    }

    context.read<OrderProvider>().addOrder(selectedItems);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Orden enviada a cocina'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva orden'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: total > 0 ? confirmOrder : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Confirmar orden'),
              ),
            ],
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: availableProducts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = availableProducts[index];
          final quantity = getQuantity(product.id);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
                  Text('\$${product.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        onPressed: quantity > 0
                            ? () => decreaseQuantity(product.id)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        quantity.toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton.filled(
                        onPressed: () => increaseQuantity(product.id),
                        icon: const Icon(Icons.add),
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