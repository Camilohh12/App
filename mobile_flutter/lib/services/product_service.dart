import '../models/category.dart';
import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  const ProductService(this._client);

  final ApiClient _client;

  /// GET /api/products
  Future<List<Product>> getProducts() async {
    final response = await _client.get('/products');
    final list = response as List<dynamic>;

    return list
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/categories
  Future<List<Category>> getCategories() async {
    final response = await _client.get('/categories');
    final list = response as List<dynamic>;

    return list
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/products (solo admin)
  Future<Product> createProduct({
    required String name,
    required double price,
    required int stock,
    required int categoryId,
  }) async {
    final response = await _client.post(
      '/products',
      body: {
        'name': name,
        'price': price,
        'stock': stock,
        'categoryId': categoryId,
      },
    );

    return Product.fromJson(response as Map<String, dynamic>);
  }

  /// DELETE /api/products/:id (solo admin)
  Future<void> deleteProduct(int productId) async {
    await _client.delete('/products/$productId');
  }

  /// PUT /api/products/:id (solo admin) — aquí solo se usa para
  /// activar/desactivar; el backend conserva el resto de campos.
  Future<Product> setActive(int productId, bool active) async {
    final response = await _client.put(
      '/products/$productId',
      body: {'active': active},
    );

    return Product.fromJson(response as Map<String, dynamic>);
  }

  /// PATCH /api/products/:id/stock
  /// Envía `stock` para fijar un valor exacto, o `delta` para sumar
  /// (positivo) o restar (negativo) sobre el stock actual.
  Future<Product> updateStock(
      int productId, {
        int? stock,
        int? delta,
      }) async {
    final response = await _client.patch(
      '/products/$productId/stock',
      body: {
        if (stock != null) 'stock': stock,
        if (delta != null) 'delta': delta,
      },
    );

    return Product.fromJson(response as Map<String, dynamic>);
  }
}
