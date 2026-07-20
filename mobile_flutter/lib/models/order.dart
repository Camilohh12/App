import 'product.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
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

  const FoodOrder({
    required this.id,
    required this.items,
    this.status = OrderStatus.pending,
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
  }) {
    return FoodOrder(
      id: id,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }
}