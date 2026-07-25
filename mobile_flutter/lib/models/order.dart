import 'product.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
}

enum PaymentMethod {
  cash,
  card,
  transfer,
}

class OrderItem {
  final Product product;
  final int quantity;

  const OrderItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;
}

class FoodOrder {
  final int id;
  final List<OrderItem> items;
  final OrderStatus status;
  final PaymentMethod? paymentMethod;
  final double? amountReceived;
  final double? change;
  final DateTime? completedAt;
  final bool stockDiscounted;

  const FoodOrder({
    required this.id,
    required this.items,
    this.status = OrderStatus.pending,
    this.paymentMethod,
    this.amountReceived,
    this.change,
    this.completedAt,
    this.stockDiscounted = false,
  });

  double get total {
    return items.fold(
      0,
          (sum, item) => sum + item.subtotal,
    );
  }

  FoodOrder copyWith({
    List<OrderItem>? items,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    double? amountReceived,
    double? change,
    DateTime? completedAt,
    bool? stockDiscounted,
  }) {
    return FoodOrder(
      id: id,
      items: items ?? this.items,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      change: change ?? this.change,
      completedAt: completedAt ?? this.completedAt,
      stockDiscounted: stockDiscounted ?? this.stockDiscounted,
    );
  }
}