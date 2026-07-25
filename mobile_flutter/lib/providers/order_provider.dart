import 'package:flutter/material.dart';

import '../models/order.dart';
import 'product_provider.dart';

enum PaymentResult {
  success,
  orderNotReady,
  insufficientAmount,
  insufficientStock,
  alreadyProcessed,
}

class OrderProvider extends ChangeNotifier {
  final List<FoodOrder> _orders = [];

  List<FoodOrder> get orders => List.unmodifiable(_orders);

  List<FoodOrder> get activeOrders {
    return _orders
        .where((order) => order.status != OrderStatus.completed)
        .toList();
  }

  List<FoodOrder> get readyOrders {
    return _orders
        .where((order) => order.status == OrderStatus.ready)
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
    if (items.isEmpty) return;

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

    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(
      status: status,
    );

    notifyListeners();
  }

  PaymentResult completePayment({
    required int orderId,
    required PaymentMethod paymentMethod,
    required double amountReceived,
    required ProductProvider productProvider,
  }) {
    final index = _orders.indexWhere(
          (order) => order.id == orderId,
    );

    if (index == -1) return PaymentResult.orderNotReady;

    final order = _orders[index];

    if (order.stockDiscounted) {
      return PaymentResult.alreadyProcessed;
    }

    if (order.status != OrderStatus.ready) {
      return PaymentResult.orderNotReady;
    }

    if (paymentMethod == PaymentMethod.cash &&
        amountReceived < order.total) {
      return PaymentResult.insufficientAmount;
    }

    // Validación final de stock justo antes de confirmar el cobro.
    if (!productProvider.discountOrderStock(order.items)) {
      return PaymentResult.insufficientStock;
    }

    final calculatedChange =
    paymentMethod == PaymentMethod.cash
        ? amountReceived - order.total
        : 0.0;

    _orders[index] = order.copyWith(
      status: OrderStatus.completed,
      paymentMethod: paymentMethod,
      amountReceived: amountReceived,
      change: calculatedChange,
      completedAt: DateTime.now(),
      stockDiscounted: true,
    );

    notifyListeners();
    return PaymentResult.success;
  }
}