import 'api_client.dart';

/// Consumo de órdenes. Mientras el backend no esté disponible,
/// OrderProvider sigue manejando las órdenes en memoria; este
/// servicio queda listo para sustituir ese modo local.
///
/// Se reciben/devuelven `Map<String, dynamic>` en lugar de FoodOrder
/// porque el contrato exacto del backend (nombres de campos, forma
/// de anidar los items) todavía no está definido; cuando exista,
/// conviene agregar FoodOrder.fromJson/toJson y tipar estos métodos.
class OrderService {
  const OrderService(this._client);

  final ApiClient _client;

  /// POST /api/orders
  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> payload,
      ) async {
    final response = await _client.post('/orders', body: payload);
    return response as Map<String, dynamic>;
  }

  /// GET /api/orders
  Future<List<dynamic>> getOrders() async {
    final response = await _client.get('/orders');
    return response as List<dynamic>;
  }

  /// PATCH /api/orders/:id/status
  Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final response = await _client.patch(
      '/orders/$orderId/status',
      body: {'status': status},
    );

    return response as Map<String, dynamic>;
  }
}
