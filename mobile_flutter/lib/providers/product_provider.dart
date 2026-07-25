import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [
    const Product(
      id: 1,
      name: 'Hamburguesa clásica',
      price: 75,
      category: 'Hamburguesas',
      stock: 15,
    ),
    const Product(
      id: 2,
      name: 'Papas fritas',
      price: 40,
      category: 'Complementos',
      stock: 20,
    ),
    const Product(
      id: 3,
      name: 'Refresco',
      price: 25,
      category: 'Bebidas',
      stock: 30,
    ),
    const Product(
      id: 4,
      name: 'Pastel de chocolate',
      price: 45,
      category: 'Postres',
      stock: 8,
    ),
  ];

  List<Product> get products => List.unmodifiable(_products);

  List<Product> get availableProducts {
    return _products
        .where((product) => product.active && product.stock > 0)
        .toList();
  }

  List<Product> get lowStockProducts {
    return _products
        .where((product) => product.active && product.stock <= 5)
        .toList();
  }

  Product? findById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  bool hasEnoughStock(int productId, int quantity) {
    final product = findById(productId);

    if (product == null) {
      return false;
    }

    return product.stock >= quantity;
  }

  bool reduceStock(int productId, int quantity) {
    final index = _products.indexWhere(
          (product) => product.id == productId,
    );

    if (index == -1 || _products[index].stock < quantity) {
      return false;
    }

    _products[index] = _products[index].copyWith(
      stock: _products[index].stock - quantity,
    );

    notifyListeners();
    return true;
  }

  Map<int, int> _aggregateQuantities(List<OrderItem> items) {
    final Map<int, int> quantities = {};

    for (final item in items) {
      quantities.update(
        item.product.id,
            (value) => value + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    return quantities;
  }

  /// Verifica que todos los productos de la orden tengan stock
  /// suficiente, agrupando cantidades por producto para evitar
  /// contar dos veces el mismo producto repetido en varios items.
  bool canFulfillOrder(List<OrderItem> items) {
    final quantities = _aggregateQuantities(items);

    for (final entry in quantities.entries) {
      final product = findById(entry.key);

      if (product == null || !product.active || product.stock < entry.value) {
        return false;
      }
    }

    return true;
  }

  /// Descuenta el stock de todos los productos de una orden de forma
  /// atómica: si algún producto no tiene stock suficiente, no se
  /// descuenta nada.
  bool discountOrderStock(List<OrderItem> items) {
    if (!canFulfillOrder(items)) {
      return false;
    }

    final quantities = _aggregateQuantities(items);

    quantities.forEach((productId, quantity) {
      final index = _products.indexWhere(
            (product) => product.id == productId,
      );

      _products[index] = _products[index].copyWith(
        stock: _products[index].stock - quantity,
      );
    });

    notifyListeners();
    return true;
  }
}