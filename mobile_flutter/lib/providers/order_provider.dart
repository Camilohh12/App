import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import 'product_provider.dart';
import 'table_provider.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._orderService, this._paymentService);

  final OrderService _orderService;
  final PaymentService _paymentService;

  List<FoodOrder> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FoodOrder> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    final now = DateTime.now();

    return completedOrders
        .where((order) {
      final date = order.completedAt;
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    })
        .fold(0.0, (sum, order) => sum + order.total);
  }

  int get pendingOrders => activeOrders.length;

  /// Vuelve a consultar todas las órdenes al backend. Se llama tras
  /// cada creación/cambio de estado/pago para reflejar el estado
  /// real, en vez de mutar la lista local.
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawOrders = await _orderService.getOrders();

      _orders = rawOrders
          .map((json) => FoodOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible conectar con el servidor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea una nueva orden. Para servicio en mesa (`dineIn`) se
  /// requiere `tableId`; el backend valida que la mesa exista y esté
  /// disponible, y la marca como ocupada de forma atómica. Devuelve
  /// null si todo salió bien, o un mensaje de error para mostrar.
  Future<String?> addOrder(
      List<OrderItem> items, {
        required ServiceType serviceType,
        int? tableId,
        required TableProvider tableProvider,
      }) async {
    if (items.isEmpty) return 'La orden debe tener al menos un producto';

    if (serviceType == ServiceType.dineIn && tableId == null) {
      return 'Debes seleccionar una mesa';
    }

    try {
      await _orderService.createOrder({
        'serviceType': serviceType.name,
        if (serviceType == ServiceType.dineIn) 'tableId': tableId,
        'items': items
            .map((item) => {
          'productId': item.product.id,
          'quantity': item.quantity,
          if (item.note != null && item.note!.isNotEmpty)
            'note': item.note,
        })
            .toList(),
      });

      await Future.wait([
        refresh(),
        tableProvider.refresh(),
      ]);

      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }

  /// Cambia el estado de una orden (`preparing` o `ready`).
  Future<String?> updateStatus(
      int orderId,
      OrderStatus status,
      ) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        status: status.name,
      );

      await refresh();
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }

  /// Cancela una orden en estado pendiente o en preparación. El
  /// backend exige rol administrador y libera la mesa si tenía una;
  /// como nunca llega a /api/payments, no se descuenta stock.
  Future<String?> cancelOrder(
      int orderId, {
        required TableProvider tableProvider,
      }) async {
    try {
      await _orderService.updateOrderStatus(
        orderId: orderId,
        status: 'cancelled',
      );

      await Future.wait([
        refresh(),
        tableProvider.refresh(),
      ]);

      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }

  /// Registra el cobro de una orden lista. El backend valida stock y
  /// monto, descuenta el inventario y libera la mesa de forma
  /// atómica. Devuelve null si todo salió bien, o el mensaje de
  /// error del servidor (monto insuficiente, stock insuficiente,
  /// orden no lista, etc.) para mostrar tal cual al usuario.
  Future<String?> completePayment({
    required int orderId,
    required PaymentMethod paymentMethod,
    required double amountReceived,
    required ProductProvider productProvider,
    required TableProvider tableProvider,
  }) async {
    try {
      await _paymentService.createPayment({
        'orderId': orderId,
        'paymentMethod': paymentMethod.name,
        'amountReceived': amountReceived,
      });

      await Future.wait([
        refresh(),
        productProvider.refresh(),
        tableProvider.refresh(),
      ]);

      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }
}
