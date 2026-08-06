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

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as int,
      number: json['number'] as int,
      status: TableStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => TableStatus.available,
      ),
      qrCode: json['qrCode'] as String,
    );
  }

}
