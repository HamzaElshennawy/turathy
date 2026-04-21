import '../../../core/helper/dio/end_points.dart';

class ProductModel {
  static const String saleModeDirectPurchase = 'DIRECT_PURCHASE';
  static const String saleModePreorderContact = 'PREORDER_CONTACT';

  final int id;
  final int? userId;
  final String? title;
  final String? name;
  final String? description;
  final double? price;
  final String saleMode;
  final String? imageUrl;
  final String? category;
  final String? brand;
  final int stock;
  final double discount;
  final double rating;
  final int reviews;
  final String? material;
  final String? approximateAge;
  final String? condition;
  final String? origin;
  final String? country;
  final int? date;
  final String? itemType;
  final String? denomination;
  final bool? isGraded;
  final String? gradingCompany;
  final String? gradeDesignation;
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

  bool get hasDiscount => discount > 0;
  bool get isPreorderContact => saleMode == saleModePreorderContact;
  bool get isDirectPurchase => !isPreorderContact;

  double get discountedPrice {
    final basePrice = price ?? 0;
    if (isPreorderContact || !hasDiscount) return basePrice;
    final normalizedDiscount = discount.clamp(0, 100);
    return basePrice * (1 - (normalizedDiscount / 100));
  }

  String get stockLabel => stock <= 0 ? 'out' : stock <= 3 ? 'low' : 'in';

  const ProductModel({
    required this.id,
    this.userId,
    required this.title,
    required this.name,
    required this.description,
    required this.price,
    this.saleMode = saleModeDirectPurchase,
    required this.imageUrl,
    required this.category,
    required this.brand,
    required this.stock,
    required this.discount,
    required this.rating,
    required this.reviews,
    this.material,
    this.approximateAge,
    this.condition,
    this.origin,
    this.country,
    this.date,
    this.itemType,
    this.denomination,
    this.isGraded,
    this.gradingCompany,
    this.gradeDesignation,
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
          saleMode == other.saleMode &&
          imageUrl == other.imageUrl &&
          category == other.category &&
          brand == other.brand &&
          stock == other.stock &&
          discount == other.discount &&
          rating == other.rating &&
          reviews == other.reviews &&
          material == other.material &&
          approximateAge == other.approximateAge &&
          condition == other.condition &&
          origin == other.origin &&
          country == other.country &&
          date == other.date &&
          itemType == other.itemType &&
          denomination == other.denomination &&
          isGraded == other.isGraded &&
          gradingCompany == other.gradingCompany &&
          gradeDesignation == other.gradeDesignation &&
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
      saleMode.hashCode ^
      imageUrl.hashCode ^
      category.hashCode ^
      brand.hashCode ^
      stock.hashCode ^
      discount.hashCode ^
      rating.hashCode ^
      reviews.hashCode ^
      material.hashCode ^
      approximateAge.hashCode ^
      condition.hashCode ^
      origin.hashCode ^
      country.hashCode ^
      date.hashCode ^
      itemType.hashCode ^
      denomination.hashCode ^
      isGraded.hashCode ^
      gradingCompany.hashCode ^
      gradeDesignation.hashCode ^
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
    String? saleMode,
    String? imageUrl,
    String? category,
    String? brand,
    int? stock,
    double? discount,
    double? rating,
    int? reviews,
    String? material,
    String? approximateAge,
    String? condition,
    String? origin,
    String? country,
    int? date,
    String? itemType,
    String? denomination,
    bool? isGraded,
    String? gradingCompany,
    String? gradeDesignation,
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
      saleMode: saleMode ?? this.saleMode,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      stock: stock ?? this.stock,
      discount: discount ?? this.discount,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      material: material ?? this.material,
      approximateAge: approximateAge ?? this.approximateAge,
      condition: condition ?? this.condition,
      origin: origin ?? this.origin,
      country: country ?? this.country,
      date: date ?? this.date,
      itemType: itemType ?? this.itemType,
      denomination: denomination ?? this.denomination,
      isGraded: isGraded ?? this.isGraded,
      gradingCompany: gradingCompany ?? this.gradingCompany,
      gradeDesignation: gradeDesignation ?? this.gradeDesignation,
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
      'sale_mode': saleMode,
      'imageUrl': imageUrl,
      'category': category,
      'brand': brand,
      'stock': stock,
      'discount': discount,
      'rating': rating,
      'reviews': reviews,
      'material': material,
      'approximateAge': approximateAge,
      'condition': condition,
      'origin': origin,
      'country': country,
      'date': date,
      'item_type': itemType,
      'denomination': denomination,
      'is_graded': isGraded,
      'grading_company': gradingCompany,
      'grade_designation': gradeDesignation,
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
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      title: json['title'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      saleMode: (json['sale_mode'] ?? saleModeDirectPurchase).toString(),
      imageUrl: (json['imageUrl'] ?? json['image']) as String?,
      category: json['category'] as String?,
      brand: json['brand'] as String?,
      stock: json['stock'] != null ? (int.tryParse(json['stock'].toString()) ?? 0) : 0,
      discount: json['discount'] != null ? (double.tryParse(json['discount'].toString()) ?? 0.0) : 0.0,
      rating: json['rating'] != null ? (double.tryParse(json['rating'].toString()) ?? 0.0) : 0.0,
      reviews: json['reviews'] != null ? (int.tryParse(json['reviews'].toString()) ?? 0) : 0,
      material: json['material'] as String?,
      approximateAge: json['approximateAge'] as String?,
      condition: json['condition'] as String?,
      origin: json['origin'] as String?,
      country: json['country'] as String?,
      date: json['date'] != null ? int.tryParse(json['date'].toString()) : null,
      itemType: (json['item_type'] ?? json['itemType']) as String?,
      denomination: json['denomination'] as String?,
      isGraded: () {
        final val = json['is_graded'] ?? json['isGraded'];
        if (val == null) return null;
        if (val is bool) return val;
        return val.toString() == 'true' || val.toString() == '1';
      }(),
      gradingCompany: (json['grading_company'] ?? json['gradingCompany']) as String?,
      gradeDesignation: (json['grade_designation'] ?? json['gradeDesignation']) as String?,
      grade: json['grade'] != null ? int.tryParse(json['grade'].toString()) : null,
      metalWeight: json['metal_weight'] != null ? double.tryParse(json['metal_weight'].toString()) : null,
      metalType: json['metal_type'] as String?,
      metalDiameter: json['metal_diameter'] != null ? double.tryParse(json['metal_diameter'].toString()) : null,
      metalThickness: json['metal_thickness'] != null ? double.tryParse(json['metal_thickness'].toString()) : null,
      metalFineness: json['metal_fineness'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as Iterable)
          : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
