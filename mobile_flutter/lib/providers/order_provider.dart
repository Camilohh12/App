import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final List<FoodOrder> _orders = [];

  List<FoodOrder> get orders => List.unmodifiable(_orders);

  List<FoodOrder> get activeOrders {
    return _orders
        .where((order) => order.status != OrderStatus.completed)
        .toList();
  }

  List<FoodOrder> get completedOrders {
    return _orders
        .where((order) => order.status == OrderStatus.completed)
        .toList();
  }

  double get dailySales {
    return completedOrders.fold(
      0,
          (sum, order) => sum + order.total,
    );
  }

  int get pendingOrders => activeOrders.length;

  void addOrder(List<OrderItem> items) {
    if (items.isEmpty) {
      return;
    }

    final order = FoodOrder(
      id: _orders.length + 1,
      items: items,
    );

    _orders.add(order);
    notifyListeners();
  }

  void updateStatus(
      int orderId,
      OrderStatus status,
      ) {
    final index = _orders.indexWhere(
          (order) => order.id == orderId,
    );

    if (index == -1) {
      return;
    }

    _orders[index] = _orders[index].copyWith(
      status: status,
    );

    notifyListeners();
  }
}