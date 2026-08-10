/// Área donde se prepara un producto. El backend todavía no tiene esta
/// columna, así que si no viene explícita se deriva del nombre de la
/// categoría (ver [PreparationArea.fromCategoryName]).
enum PreparationArea {
  bar,
  kitchen;

  /// Deriva el área a partir del nombre de categoría, para productos
  /// que vienen del backend (sin esta columna todavía) o cuya
  /// categoría no se ha catalogado a mano. Por defecto asume cocina,
  /// que es lo más seguro para categorías desconocidas.
  static PreparationArea fromCategoryName(String category) {
    final normalized = category.toLowerCase();

    const barKeywords = [
      'cerveza',
      'coctel',
      'cóctel',
      'destilado',
      'tequila',
      'whisky',
      'ron',
      'copa',
      'trago',
      'bebida',
      'refresco',
      'agua',
      'promocion',
      'promoción',
    ];

    final isBar = barKeywords.any(normalized.contains);
    return isBar ? PreparationArea.bar : PreparationArea.kitchen;
  }
}

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final int stock;
  final bool active;
  final PreparationArea preparationArea;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    required this.stock,
    this.active = true,
    PreparationArea? preparationArea,
    this.imageUrl,
  }) : preparationArea =
            preparationArea ?? PreparationArea.fromCategoryName(category);

  factory Product.fromJson(Map<String, dynamic> json) {
    // La API devuelve `category` como objeto anidado {id, name} en
    // /api/products, pero el detalle de una orden solo trae el
    // producto sin esa relación incluida.
    final categoryField = json['category'];
    final categoryName = categoryField is Map<String, dynamic>
        ? (categoryField['name'] as String? ?? '')
        : (categoryField as String? ?? '');

    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      category: categoryName,
      stock: json['stock'] as int,
      active: json['active'] as bool? ?? true,
      // El backend todavía no envía esta columna: se deriva del
      // nombre de categoría en el constructor si no viene en el JSON.
      preparationArea: json['preparationArea'] != null
          ? PreparationArea.values.firstWhere(
              (area) => area.name == json['preparationArea'],
              orElse: () => PreparationArea.fromCategoryName(categoryName),
            )
          : null,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Serialización genérica de la entidad (para caché local o depuración).
  /// Los endpoints de escritura (crear/actualizar producto) usan payloads
  /// más angostos construidos en `product_service.dart` — por ejemplo,
  /// envían `categoryId` en vez de `category`, que aquí es el nombre.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'category': category,
      'stock': stock,
      'active': active,
      'preparationArea': preparationArea.name,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    bool? active,
    PreparationArea? preparationArea,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      active: active ?? this.active,
      preparationArea: preparationArea ?? this.preparationArea,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
