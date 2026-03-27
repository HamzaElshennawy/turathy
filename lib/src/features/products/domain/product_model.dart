import '../../../core/helper/dio/end_points.dart';

class ProductModel {
  final int id;
  final int? userId;
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
  final String? country;
  final int? date;
  final String? denomination;
  final bool? isGraded;
  final String? gradingCompany;
  final int? grade;
  final double? metalWeight;
  final String? metalType;
  final double? metalDiameter;
  final double? metalThickness;
  final String? metalFineness;
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
    this.userId,
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
    this.country,
    this.date,
    this.denomination,
    this.isGraded,
    this.gradingCompany,
    this.grade,
    this.metalWeight,
    this.metalType,
    this.metalDiameter,
    this.metalThickness,
    this.metalFineness,
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
          userId == other.userId &&
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
          country == other.country &&
          date == other.date &&
          denomination == other.denomination &&
          isGraded == other.isGraded &&
          gradingCompany == other.gradingCompany &&
          grade == other.grade &&
          metalWeight == other.metalWeight &&
          metalType == other.metalType &&
          metalDiameter == other.metalDiameter &&
          metalThickness == other.metalThickness &&
          metalFineness == other.metalFineness &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt);

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
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
      country.hashCode ^
      date.hashCode ^
      denomination.hashCode ^
      isGraded.hashCode ^
      gradingCompany.hashCode ^
      grade.hashCode ^
      metalWeight.hashCode ^
      metalType.hashCode ^
      metalDiameter.hashCode ^
      metalThickness.hashCode ^
      metalFineness.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  ProductModel copyWith({
    int? id,
    int? userId,
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
    String? country,
    int? date,
    String? denomination,
    bool? isGraded,
    String? gradingCompany,
    int? grade,
    double? metalWeight,
    String? metalType,
    double? metalDiameter,
    double? metalThickness,
    String? metalFineness,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      country: country ?? this.country,
      date: date ?? this.date,
      denomination: denomination ?? this.denomination,
      isGraded: isGraded ?? this.isGraded,
      gradingCompany: gradingCompany ?? this.gradingCompany,
      grade: grade ?? this.grade,
      metalWeight: metalWeight ?? this.metalWeight,
      metalType: metalType ?? this.metalType,
      metalDiameter: metalDiameter ?? this.metalDiameter,
      metalThickness: metalThickness ?? this.metalThickness,
      metalFineness: metalFineness ?? this.metalFineness,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
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
      'country': country,
      'date': date,
      'denomination': denomination,
      'is_graded': isGraded,
      'grading_company': gradingCompany,
      'grade': grade,
      'metal_weight': metalWeight,
      'metal_type': metalType,
      'metal_diameter': metalDiameter,
      'metal_thickness': metalThickness,
      'metal_fineness': metalFineness,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      title: json['title'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      imageUrl: (json['imageUrl'] ?? json['image']) as String?,
      category: json['category'] as String?,
      brand: json['brand'] as String?,
      stock: json['stock'] as int? ?? 0,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      reviews: json['reviews'] as int? ?? 0,
      material: json['material'] as String?,
      approximateAge: json['approximateAge'] as String?,
      condition: json['condition'] as String?,
      origin: json['origin'] as String?,
      country: json['country'] as String?,
      date: json['date'] as int?,
      denomination: json['denomination'] as String?,
      isGraded: (json['is_graded'] ?? json['isGraded']) as bool?,
      gradingCompany: (json['grading_company'] ?? json['gradingCompany']) as String?,
      grade: json['grade'] as int?,
      metalWeight: json['metal_weight'] != null ? (json['metal_weight'] as num).toDouble() : null,
      metalType: json['metal_type'] as String?,
      metalDiameter: json['metal_diameter'] != null ? (json['metal_diameter'] as num).toDouble() : null,
      metalThickness: json['metal_thickness'] != null ? (json['metal_thickness'] as num).toDouble() : null,
      metalFineness: json['metal_fineness'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as Iterable)
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
    );
  }
}
