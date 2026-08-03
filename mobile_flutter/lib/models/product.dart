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
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      stock: json['stock'] as int,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'stock': stock,
      'active': active,
    };
  }

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