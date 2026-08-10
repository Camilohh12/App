import 'api_client.dart';

/// Consumo de reportes contra el backend real.
class ReportService {
  const ReportService(this._client);

  final ApiClient _client;

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
