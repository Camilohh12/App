import 'package:flutter/material.dart';

import '../models/table_model.dart';
import '../services/api_client.dart';
import '../services/table_service.dart';

class TableProvider extends ChangeNotifier {
  TableProvider(this._tableService);

  final TableService _tableService;

  List<TableModel> _tables = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TableModel> get tables => List.unmodifiable(_tables);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TableModel> get availableTables {
    return _tables
        .where((table) => table.status == TableStatus.available)
        .toList();
  }

  TableModel? findById(int id) {
    try {
      return _tables.firstWhere((table) => table.id == id);
    } catch (_) {
      return null;
    }
  }

  TableModel? findByQrCode(String code) {
    try {
      return _tables.firstWhere((table) => table.qrCode == code);
    } catch (_) {
      return null;
    }
  }

  /// Carga las mesas desde la API. Ocupar/liberar una mesa ya no se
  /// hace localmente: el backend lo resuelve de forma atómica al
  /// crear una orden, cobrarla o cancelarla, así que aquí solo se
  /// vuelve a consultar el estado real.
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tables = await _tableService.getTables();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible conectar con el servidor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
