import '../models/table_model.dart';
import 'api_client.dart';

class TableService {
  const TableService(this._client);

  final ApiClient _client;

  /// GET /api/tables
  Future<List<TableModel>> getTables() async {
    final response = await _client.get('/tables');
    final list = response as List<dynamic>;

    return list
        .map((json) => TableModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
