import 'product.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled,
}

enum PaymentMethod {
  cash,
  card,
  transfer,
}

enum ServiceType {
  dineIn,
  takeaway,
}

class OrderItem {
  final Product product;
  final int quantity;
  final String? note;

  const OrderItem({
    required this.product,
    required this.quantity,
    this.note,
  });

  double get subtotal => product.price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      note: json['note'] as String?,
    );
  }

  /// Forma que espera el backend al crear una orden o agregar una
  /// ronda (`POST /api/orders`, `POST /api/orders/:id/items`): manda
  /// `productId`, no el producto completo.
  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'quantity': quantity,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}

class FoodOrder {
  final int id;
  final List<OrderItem> items;
  final OrderStatus status;
  final PaymentMethod? paymentMethod;
  final double? amountReceived;
  final double? change;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final ServiceType serviceType;
  final int? tableId;

  const FoodOrder({
    required this.id,
    required this.items,
    this.status = OrderStatus.pending,
    this.paymentMethod,
    this.amountReceived,
    this.change,
    this.createdAt,
    this.completedAt,
    this.serviceType = ServiceType.takeaway,
    this.tableId,
  });

  double get total {
    return items.fold(
      0,
          (sum, item) => sum + item.subtotal,
    );
  }

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    final detailsJson = json['details'] as List<dynamic>? ?? [];

    return FoodOrder(
      id: json['id'] as int,
      items: detailsJson
          .map((detail) => OrderItem.fromJson(detail as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (method) => method.name == json['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      amountReceived: (json['amountReceived'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      createdAt: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      serviceType: json['serviceType'] == 'dineIn'
          ? ServiceType.dineIn
          : ServiceType.takeaway,
      tableId: json['tableId'] as int?,
    );
  }
}