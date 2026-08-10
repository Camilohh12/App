import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/providers/order_provider.dart';
import 'package:mobile_flutter/services/api_client.dart';
import 'package:mobile_flutter/services/order_service.dart';
import 'package:mobile_flutter/services/payment_service.dart';

/// Servicio falso: no llama a la red, solo devuelve el JSON que se le
/// haya dado. Extiende (no implementa) OrderService porque su campo
/// `_client` es privado a esa librería y no se podría "implementar"
/// desde el archivo de prueba.
class FakeOrderService extends OrderService {
  FakeOrderService(this._orders) : super(ApiClient());

  final List<Map<String, dynamic>> _orders;

  @override
  Future<List<dynamic>> getOrders() async => _orders;
}

Map<String, dynamic> _completedOrderJson({
  required int id,
  required DateTime completedAt,
  required double total,
}) {
  return {
    'id': id,
    'status': 'completed',
    'paymentMethod': 'cash',
    'amountReceived': total,
    'change': 0.0,
    'date': completedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'serviceType': 'takeaway',
    'tableId': null,
    'details': [
      {
        'quantity': 1,
        'note': null,
        'product': {
          'id': 1,
          'name': 'Cerveza nacional',
          'price': total,
          'category': {'id': 1, 'name': 'Cervezas'},
          'stock': 10,
          'active': true,
        },
      },
    ],
  };
}

Map<String, dynamic> _pendingOrderJson(int id) {
  return {
    'id': id,
    'status': 'pending',
    'serviceType': 'takeaway',
    'details': <Map<String, dynamic>>[],
  };
}

void main() {
  // Regresión: dailySales sumaba órdenes completadas de CUALQUIER día,
  // no solo de hoy. Ver historial del proyecto — este fue un bug real
  // encontrado al probar en dispositivo físico.
  test('dailySales solo suma órdenes completadas hoy, no de otros días', () async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final orderProvider = OrderProvider(
      FakeOrderService([
        _completedOrderJson(id: 1, completedAt: yesterday, total: 220),
        _completedOrderJson(id: 2, completedAt: now, total: 90),
      ]),
      PaymentService(ApiClient()),
    );

    await orderProvider.refresh();

    expect(orderProvider.dailySales, 90);
  });

  test('activeOrders excluye órdenes completadas y canceladas', () async {
    final now = DateTime.now();

    final orderProvider = OrderProvider(
      FakeOrderService([
        _pendingOrderJson(1),
        _completedOrderJson(id: 2, completedAt: now, total: 50),
      ]),
      PaymentService(ApiClient()),
    );

    await orderProvider.refresh();

    expect(orderProvider.activeOrders.length, 1);
    expect(orderProvider.activeOrders.first.id, 1);
    expect(orderProvider.pendingOrders, 1);
  });
}
