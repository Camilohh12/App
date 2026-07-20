import 'package:flutter/material.dart';

import '../models/product.dart';

const availableProducts = [
  Product(
    id: 1,
    name: 'Hamburguesa clásica',
    price: 75,
    category: 'Hamburguesas',
  ),
  Product(
    id: 2,
    name: 'Papas fritas',
    price: 40,
    category: 'Complementos',
  ),
  Product(
    id: 3,
    name: 'Refresco',
    price: 25,
    category: 'Bebidas',
  ),
  Product(
    id: 4,
    name: 'Pastel de chocolate',
    price: 45,
    category: 'Postres',
  ),
];

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: availableProducts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = availableProducts[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.fastfood),
              ),
              title: Text(
                product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(product.category),
              trailing: Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        },
      ),
    );
  }
}