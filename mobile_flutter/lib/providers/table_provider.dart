import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/demo_tables.dart';
import '../models/table_model.dart';
import '../services/api_client.dart';
import '../services/table_service.dart';

class TableProvider extends ChangeNotifier {
  TableProvider(this._tableService);

  final TableService _tableService;

  List<TableModel> _tables = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Mesero asignado por mesa. El backend todavía no tiene dónde
  /// persistir esto, así que se guarda en memoria y se vuelve a
  /// fusionar sobre la lista tras cada [refresh] (incluido el
  /// auto-refresco en segundo plano), para que no se pierda mientras
  /// la mesa siga ocupada.
  final Map<int, String> _waiterNames = {};

  List<TableModel> get tables => List.unmodifiable(_tables);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TableModel> get availableTables {
    return _tables
        .where((table) => table.status == TableStatus.available)
        .toList();
  }

  List<TableModel> get occupiedTables {
    return _tables
        .where((table) => table.status == TableStatus.occupied)
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
    if (AppConfig.useLocalMode) {
      _applyFetched(demoTables);
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applyFetched(await _tableService.getTables());
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible conectar con el servidor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fusiona la lista recién obtenida (API o demo local) con el
  /// mesero en caché, y descarta el mesero de cualquier mesa que ya
  /// no esté ocupada (se cobró, se canceló la orden, etc.) para que
  /// no reaparezca si esa mesa se vuelve a ocupar después.
  void _applyFetched(List<TableModel> fetched) {
    final occupiedIds = fetched
        .where((table) => table.status == TableStatus.occupied)
        .map((table) => table.id)
        .toSet();

    _waiterNames.removeWhere((tableId, _) => !occupiedIds.contains(tableId));

    _tables = fetched.map((table) {
      final waiterName = _waiterNames[table.id];
      return waiterName == null ? table : table.copyWith(waiterName: waiterName);
    }).toList();
  }

  /// Asocia un mesero a una mesa (ej. al abrirla desde [TablesScreen]).
  /// Se conserva localmente porque el backend todavía no tiene una
  /// columna para esto; se limpia solo cuando la mesa vuelve a estar
  /// disponible.
  void assignWaiter(int tableId, String waiterName) {
    if (waiterName.trim().isEmpty) return;

    _waiterNames[tableId] = waiterName.trim();

    final index = _tables.indexWhere((table) => table.id == tableId);
    if (index != -1) {
      _tables[index] = _tables[index].copyWith(waiterName: waiterName.trim());
      notifyListeners();
    }
  }

  String? waiterNameFor(int tableId) => _waiterNames[tableId];
}
