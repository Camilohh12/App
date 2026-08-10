import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/models/product.dart';

void main() {
  group('PreparationArea.fromCategoryName', () {
    test('categorías de bebidas alcohólicas y cócteles se asignan a barra', () {
      expect(PreparationArea.fromCategoryName('Cervezas'), PreparationArea.bar);
      expect(PreparationArea.fromCategoryName('Cócteles'), PreparationArea.bar);
      expect(PreparationArea.fromCategoryName('Destilados'), PreparationArea.bar);
      expect(
        PreparationArea.fromCategoryName('Bebidas sin alcohol'),
        PreparationArea.bar,
      );
    });

    test('categorías de comida se asignan a cocina', () {
      expect(PreparationArea.fromCategoryName('Botanas'), PreparationArea.kitchen);
      expect(PreparationArea.fromCategoryName('Hamburguesas'), PreparationArea.kitchen);
    });

    test('categorías desconocidas caen a cocina por defecto (más seguro)', () {
      expect(PreparationArea.fromCategoryName('Miscelánea'), PreparationArea.kitchen);
    });
  });

  group('Product', () {
    test('deriva preparationArea de la categoría cuando no viene en el JSON', () {
      final product = Product.fromJson({
        'id': 1,
        'name': 'Mojito',
        'price': 95.0,
        'category': {'id': 2, 'name': 'Cócteles'},
        'stock': 40,
        'active': true,
      });

      expect(product.preparationArea, PreparationArea.bar);
    });

    test('respeta preparationArea explícito del JSON sobre el heurístico', () {
      final product = Product.fromJson({
        'id': 1,
        'name': 'Agua embotellada',
        'price': 20.0,
        'category': {'id': 3, 'name': 'Bebidas sin alcohol'},
        'stock': 10,
        'active': true,
        'preparationArea': 'kitchen',
      });

      expect(product.preparationArea, PreparationArea.kitchen);
    });

    test('copyWith conserva los campos no especificados', () {
      final product = Product(
        id: 1,
        name: 'Alitas',
        price: 140,
        category: 'Botanas',
        stock: 30,
      );

      final updated = product.copyWith(stock: 25);

      expect(updated.stock, 25);
      expect(updated.name, 'Alitas');
      expect(updated.preparationArea, PreparationArea.kitchen);
    });

    test('toJson/fromJson conservan el id, nombre y precio', () {
      final product = Product(
        id: 7,
        name: 'Tequila por copa',
        price: 85,
        category: 'Destilados',
        stock: 60,
      );

      final roundTripped = Product.fromJson(product.toJson());

      expect(roundTripped.id, product.id);
      expect(roundTripped.name, product.name);
      expect(roundTripped.price, product.price);
    });
  });
}
