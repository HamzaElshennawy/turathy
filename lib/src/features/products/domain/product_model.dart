import '../../../core/helper/dio/end_points.dart';

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
  final String? material;
  final String? approximateAge;
  final String? condition;
  final String? origin;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullImageUrl {
    String? url;
    if (images != null && images!.isNotEmpty) {
      url = images!.first;
    } else {
      url = imageUrl;
    }

    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${EndPoints.baseUrl}$url';
  }

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
    this.material,
    this.approximateAge,
    this.condition,
    this.origin,
    this.images,
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
          material == other.material &&
          approximateAge == other.approximateAge &&
          condition == other.condition &&
          origin == other.origin &&
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
      material.hashCode ^
      approximateAge.hashCode ^
      condition.hashCode ^
      origin.hashCode ^
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
    String? material,
    String? approximateAge,
    String? condition,
    String? origin,
    List<String>? images,
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
      material: material ?? this.material,
      approximateAge: approximateAge ?? this.approximateAge,
      condition: condition ?? this.condition,
      origin: origin ?? this.origin,
      images: images ?? this.images,
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
      'material': material,
      'approximateAge': approximateAge,
      'condition': condition,
      'origin': origin,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      title: json['title'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String?,
      brand: json['brand'] as String?,
      stock: json['stock'] as int? ?? 0,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      reviews: json['reviews'] as int? ?? 0,
      material: json['material'] as String?,
      approximateAge: json['approximateAge'] as String?,
      condition: json['condition'] as String?,
      origin: json['origin'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
