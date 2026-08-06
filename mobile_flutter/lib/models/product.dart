class Product {
  final int id;
  final String name;
  final double price;
  final String category;
  final int stock;
  final bool active;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.stock,
    this.active = true,
  });

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
      price: (json['price'] as num).toDouble(),
      category: categoryName,
      stock: json['stock'] as int,
      active: json['active'] as bool? ?? true,
    );
  }

}