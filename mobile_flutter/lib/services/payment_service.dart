import 'api_client.dart';

/// Consumo de pagos contra el backend real.
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
}
