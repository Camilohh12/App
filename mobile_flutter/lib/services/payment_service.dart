import 'api_client.dart';

/// Consumo de pagos y reportes. Mientras el backend no esté
/// disponible, OrderProvider.completePayment sigue calculando el
/// cobro localmente; este servicio queda listo para sustituir ese
/// modo local por la respuesta real del servidor.
class PaymentService {
  const PaymentService(this._client);

  final ApiClient _client;

  /// POST /api/payments
  Future<Map<String, dynamic>> createPayment(
      Map<String, dynamic> payload,
      ) async {
    final response = await _client.post('/payments', body: payload);
    return response as Map<String, dynamic>;
  }

  /// GET /api/reports/daily
  Future<Map<String, dynamic>> getDailyReport() async {
    final response = await _client.get('/reports/daily');
    return response as Map<String, dynamic>;
  }
}
