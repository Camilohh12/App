import 'package:flutter/material.dart';

import '../models/order.dart';
import 'product_provider.dart';
import 'table_provider.dart';

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
        .where((order) =>
    order.status != OrderStatus.completed &&
        order.status != OrderStatus.cancelled)
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

  /// Crea una nueva orden. Para servicio en mesa (`dineIn`) se requiere
  /// `tableId` y la mesa debe estar disponible; se marca como ocupada
  /// al confirmar. Para `takeaway` no se requiere mesa.
  bool addOrder(
      List<OrderItem> items, {
        required ServiceType serviceType,
        int? tableId,
        required TableProvider tableProvider,
      }) {
    if (items.isEmpty) return false;

    if (serviceType == ServiceType.dineIn) {
      if (tableId == null) return false;
      if (!tableProvider.occupyTable(tableId)) return false;
    }

    final order = FoodOrder(
      id: _orders.length + 1,
      items: items,
      serviceType: serviceType,
      tableId: serviceType == ServiceType.dineIn ? tableId : null,
    );

    _orders.add(order);
    notifyListeners();
    return true;
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

  /// Cancela una orden en estado pendiente o en preparación. No
  /// permite cancelar órdenes listas, ya finalizadas o ya canceladas.
  /// Como no se ha cobrado, no se descuenta stock; si la orden tenía
  /// una mesa asignada, se libera.
  bool cancelOrder(
      int orderId, {
        required TableProvider tableProvider,
      }) {
    final index = _orders.indexWhere(
          (order) => order.id == orderId,
    );

    if (index == -1) return false;

    final order = _orders[index];

    if (order.status != OrderStatus.pending &&
        order.status != OrderStatus.preparing) {
      return false;
    }

    _orders[index] = order.copyWith(status: OrderStatus.cancelled);

    if (order.serviceType == ServiceType.dineIn && order.tableId != null) {
      tableProvider.freeTable(order.tableId!);
    }

    notifyListeners();
    return true;
  }

  PaymentResult completePayment({
    required int orderId,
    required PaymentMethod paymentMethod,
    required double amountReceived,
    required ProductProvider productProvider,
    required TableProvider tableProvider,
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

    if (order.serviceType == ServiceType.dineIn && order.tableId != null) {
      tableProvider.freeTable(order.tableId!);
    }

    notifyListeners();
    return PaymentResult.success;
  }
}