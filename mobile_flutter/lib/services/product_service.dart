import '../models/product.dart';
import 'api_client.dart';

/// Consumo de productos y categorías. Mientras el backend no esté
/// disponible, ProductProvider sigue usando su lista local; este
/// servicio queda listo para reemplazarla, por ejemplo cargando
/// getProducts() en la inicialización del provider.
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
  Future<List<String>> getCategories() async {
    final response = await _client.get('/categories');
    final list = response as List<dynamic>;

    return list.map((category) => category.toString()).toList();
  }
}
