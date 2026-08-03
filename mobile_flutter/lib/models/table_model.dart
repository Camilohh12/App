enum TableStatus {
  available,
  occupied,
}

class TableModel {
  final int id;
  final int number;
  final TableStatus status;
  final String qrCode;

  const TableModel({
    required this.id,
    required this.number,
    this.status = TableStatus.available,
    required this.qrCode,
  });

  TableModel copyWith({
    int? id,
    int? number,
    TableStatus? status,
    String? qrCode,
  }) {
    return TableModel(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}
