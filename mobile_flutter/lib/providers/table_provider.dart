import 'package:flutter/material.dart';

import '../models/table_model.dart';

class TableProvider extends ChangeNotifier {
  final List<TableModel> _tables = List.generate(
    8,
        (index) => TableModel(
      id: index + 1,
      number: index + 1,
      qrCode: 'MESA-${index + 1}',
    ),
  );

  List<TableModel> get tables => List.unmodifiable(_tables);

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

  bool isAvailable(int id) {
    final table = findById(id);
    return table != null && table.status == TableStatus.available;
  }

  bool occupyTable(int id) {
    final index = _tables.indexWhere((table) => table.id == id);

    if (index == -1 || _tables[index].status == TableStatus.occupied) {
      return false;
    }

    _tables[index] = _tables[index].copyWith(
      status: TableStatus.occupied,
    );

    notifyListeners();
    return true;
  }

  bool freeTable(int id) {
    final index = _tables.indexWhere((table) => table.id == id);

    if (index == -1) return false;

    _tables[index] = _tables[index].copyWith(
      status: TableStatus.available,
    );

    notifyListeners();
    return true;
  }
}
