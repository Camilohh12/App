import 'api_client.dart';

/// Consumo de pagos y reportes contra el backend real.
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

  /// GET /api/reports/summary?period=weekly|monthly
  Future<Map<String, dynamic>> getSummaryReport(String period) async {
    final response = await _client.get('/reports/summary?period=$period');
    return response as Map<String, dynamic>;
  }
}
