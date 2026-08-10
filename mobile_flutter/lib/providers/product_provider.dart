import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/demo_catalog.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_client.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(this._productService);

  final ProductService _productService;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Product> get availableProducts {
    return _products
        .where((product) => product.active && product.stock > 0)
        .toList();
  }

  List<Product> get lowStockProducts {
    return _products
        .where((product) => product.active && product.stock <= 5)
        .toList();
  }

  List<Product> get outOfStockProducts {
    return _products
        .where((product) => product.active && product.stock == 0)
        .toList();
  }

  Product? findById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Carga los productos desde la API. Se debe llamar al iniciar
  /// sesión y cada vez que la pantalla de productos/inventario se
  /// vuelve a abrir, para reflejar cambios hechos desde otro lugar.
  Future<void> refresh() async {
    if (AppConfig.useLocalMode) {
      _products = demoBarCatalog;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No fue posible conectar con el servidor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aumenta manualmente el stock de un producto (ej. reabastecimiento).
  /// Devuelve null si todo salió bien, o un mensaje de error.
  Future<String?> increaseStock(int productId, int quantity) {
    return _adjustStock(productId, delta: quantity);
  }

  /// Disminuye manualmente el stock de un producto. El backend no
  /// permite que quede negativo.
  Future<String?> decreaseStock(int productId, int quantity) {
    return _adjustStock(productId, delta: -quantity);
  }

  /// Ajusta el stock de un producto a un valor exacto (ej. tras un
  /// conteo físico de inventario).
  Future<String?> setStock(int productId, int newStock) {
    return _adjustStock(productId, exactStock: newStock);
  }

  Future<String?> _adjustStock(
      int productId, {
        int? delta,
        int? exactStock,
      }) async {
    try {
      final updated = await _productService.updateStock(
        productId,
        stock: exactStock,
        delta: delta,
      );

      final index = _products.indexWhere(
            (product) => product.id == productId,
      );

      if (index != -1) {
        _products[index] = updated;
        notifyListeners();
      }

      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }

  /// Categorías reales del backend, para el selector al crear un
  /// producto. No se cachean: se piden cada vez que se abre el
  /// formulario para reflejar categorías nuevas.
  Future<List<Category>> loadCategories() {
    return _productService.getCategories();
  }

  /// Crea un producto nuevo. Devuelve null si todo salió bien, o un
  /// mensaje de error para mostrar.
  Future<String?> createProduct({
    required String name,
    required double price,
    required int stock,
    required int categoryId,
  }) async {
    try {
      final created = await _productService.createProduct(
        name: name,
        price: price,
        stock: stock,
        categoryId: categoryId,
      );

      _products.add(created);
      notifyListeners();

      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }

  /// Elimina un producto. Si tiene ventas registradas, el backend
  /// rechaza el borrado (restricción de integridad) y devuelve un
  /// mensaje explicando que debe desactivarse en su lugar.
  Future<String?> deleteProduct(int productId) async {
    try {
      await _productService.deleteProduct(productId);

      _products.removeWhere((product) => product.id == productId);
      notifyListeners();

      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }

  /// Activa o desactiva un producto (alternativa a eliminar cuando
  /// ya tiene ventas registradas). Un producto inactivo no aparece
  /// en el selector de nueva orden, pero se conserva en Inventario
  /// y en el historial de ventas pasadas.
  Future<String?> setActive(int productId, bool active) async {
    try {
      final updated = await _productService.setActive(productId, active);

      final index = _products.indexWhere(
            (product) => product.id == productId,
      );

      if (index != -1) {
        _products[index] = updated;
        notifyListeners();
      }

      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }
}
