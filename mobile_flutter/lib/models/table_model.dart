enum TableStatus {
  available,
  occupied,
}

class TableModel {
  final int id;
  final int number;
  final TableStatus status;
  final String qrCode;
  final int? currentOrderId;
  final String? waiterName;

  const TableModel({
    required this.id,
    required this.number,
    this.status = TableStatus.available,
    required this.qrCode,
    this.currentOrderId,
    this.waiterName,
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
      // El backend todavía no tiene estas columnas: TableProvider las
      // rellena localmente (mesero asignado) tras cada refresh.
      currentOrderId: json['currentOrderId'] as int?,
      waiterName: json['waiterName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'status': status.name,
      'qrCode': qrCode,
      if (currentOrderId != null) 'currentOrderId': currentOrderId,
      if (waiterName != null) 'waiterName': waiterName,
    };
  }

  TableModel copyWith({
    int? id,
    int? number,
    TableStatus? status,
    String? qrCode,
    int? currentOrderId,
    String? waiterName,
  }) {
    return TableModel(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      waiterName: waiterName ?? this.waiterName,
    );
  }
}
