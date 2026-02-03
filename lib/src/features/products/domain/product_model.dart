class ProductModel {
  final int id;
  final String? title;
  final String? name;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String? category;
  final String? brand;
  final int stock;
  final double rating;
  final int reviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.title,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.brand,
    required this.stock,
    required this.rating,
    required this.reviews,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          name == other.name &&
          description == other.description &&
          price == other.price &&
          imageUrl == other.imageUrl &&
          category == other.category &&
          brand == other.brand &&
          stock == other.stock &&
          rating == other.rating &&
          reviews == other.reviews &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      imageUrl.hashCode ^
      category.hashCode ^
      brand.hashCode ^
      stock.hashCode ^
      rating.hashCode ^
      reviews.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  ProductModel copyWith({
    int? id,
    String? title,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? brand,
    int? stock,
    double? rating,
    int? reviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'brand': brand,
      'stock': stock,
      'rating': rating,
      'reviews': reviews,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      title: json['title'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String,
      stock: json['stock'] as int,
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
