import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/models/order.dart';
import 'package:mobile_flutter/models/product.dart';

Product _product({required double price}) {
  return Product(
    id: 1,
    name: 'Mojito',
    price: price,
    category: 'Cócteles',
    stock: 40,
  );
}

void main() {
  group('OrderItem', () {
    test('subtotal es precio x cantidad', () {
      final item = OrderItem(product: _product(price: 95), quantity: 3);
      expect(item.subtotal, 285);
    });

    test('toJson manda productId, no el producto completo', () {
      final item = OrderItem(
        product: _product(price: 95),
        quantity: 2,
        note: 'sin azúcar',
      );

      expect(item.toJson(), {
        'productId': 1,
        'quantity': 2,
        'note': 'sin azúcar',
      });
    });

    test('toJson omite note cuando está vacío', () {
      final item = OrderItem(product: _product(price: 95), quantity: 1, note: '');
      expect(item.toJson().containsKey('note'), isFalse);
    });
  });

  group('FoodOrder', () {
    test('total suma el subtotal de todos los items', () {
      final order = FoodOrder(
        id: 1,
        items: [
          OrderItem(product: _product(price: 95), quantity: 2), // 190
          OrderItem(product: _product(price: 45), quantity: 4), // 180
        ],
      );

      expect(order.total, 370);
    });

    test('fromJson interpreta correctamente estado y método de pago', () {
      final order = FoodOrder.fromJson({
        'id': 5,
        'status': 'completed',
        'paymentMethod': 'cash',
        'amountReceived': 300.0,
        'change': 30.0,
        'date': '2026-08-06T10:00:00.000Z',
        'completedAt': '2026-08-06T10:15:00.000Z',
        'serviceType': 'dineIn',
        'tableId': 3,
        'details': [
          {
            'quantity': 2,
            'note': null,
            'product': {
              'id': 1,
              'name': 'Cerveza nacional',
              'price': 45.0,
              'category': {'id': 1, 'name': 'Cervezas'},
              'stock': 80,
              'active': true,
            },
          },
        ],
      });

      expect(order.status, OrderStatus.completed);
      expect(order.paymentMethod, PaymentMethod.cash);
      expect(order.serviceType, ServiceType.dineIn);
      expect(order.tableId, 3);
      expect(order.total, 90);
    });
  });
}
