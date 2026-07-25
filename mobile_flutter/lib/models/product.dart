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

  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? category,
    int? stock,
    bool? active,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      active: active ?? this.active,
    );
  }
}