import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/models/category.dart';
import 'package:mobile_flutter/models/product.dart';
import 'package:mobile_flutter/providers/product_provider.dart';
import 'package:mobile_flutter/services/api_client.dart';
import 'package:mobile_flutter/services/product_service.dart';

/// Igual que FakeOrderService: extiende (no implementa) porque
/// ProductService tiene un campo privado a su propia librería.
class FakeProductService extends ProductService {
  FakeProductService(this._products) : super(ApiClient());

  final List<Product> _products;

  @override
  Future<List<Product>> getProducts() async => _products;

  @override
  Future<List<Category>> getCategories() async => [];
}

void main() {
  test('availableProducts excluye inactivos y sin stock', () async {
    final productProvider = ProductProvider(
      FakeProductService([
        Product(id: 1, name: 'Mojito', price: 95, category: 'Cócteles', stock: 10),
        Product(
          id: 2,
          name: 'Producto agotado',
          price: 50,
          category: 'Botanas',
          stock: 0,
        ),
        Product(
          id: 3,
          name: 'Producto inactivo',
          price: 50,
          category: 'Botanas',
          stock: 10,
          active: false,
        ),
      ]),
    );

    await productProvider.refresh();

    expect(productProvider.availableProducts.length, 1);
    expect(productProvider.availableProducts.first.id, 1);
  });

  test('lowStockProducts incluye productos activos con 5 unidades o menos', () async {
    final productProvider = ProductProvider(
      FakeProductService([
        Product(id: 1, name: 'Con poco stock', price: 45, category: 'Cervezas', stock: 3),
        Product(id: 2, name: 'Con stock normal', price: 45, category: 'Cervezas', stock: 50),
      ]),
    );

    await productProvider.refresh();

    expect(productProvider.lowStockProducts.length, 1);
    expect(productProvider.lowStockProducts.first.name, 'Con poco stock');
  });
}
