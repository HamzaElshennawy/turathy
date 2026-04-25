import '../../../core/helper/dio/end_points.dart';

class ProductModel {
  static const String saleModeDirectPurchase = 'DIRECT_PURCHASE';
  static const String saleModePreorderContact = 'PREORDER_CONTACT';

  final int id;
  final int? userId;
  final String? titleAr;
  final String? titleEn;
  final String? title;
  final String? nameAr;
  final String? nameEn;
  final String? name;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? description;
  final double? price;
  final String saleMode;
  final String? imageUrl;
  final String? category;
  final String? brand;
  final String? sku;
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

  String localizedTitle(String languageCode) {
    if (languageCode.toLowerCase().startsWith('ar')) {
      return titleAr ?? nameAr ?? title ?? name ?? '';
    }
    return titleEn ?? nameEn ?? title ?? name ?? titleAr ?? nameAr ?? '';
  }

  String localizedDescription(String languageCode) {
    if (languageCode.toLowerCase().startsWith('ar')) {
      return descriptionAr ?? description ?? descriptionEn ?? '';
    }
    return descriptionEn ?? description ?? descriptionAr ?? '';
  }

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
    this.titleAr,
    this.titleEn,
    required this.title,
    this.nameAr,
    this.nameEn,
    required this.name,
    this.descriptionAr,
    this.descriptionEn,
    required this.description,
    required this.price,
    this.saleMode = saleModeDirectPurchase,
    required this.imageUrl,
    required this.category,
    required this.brand,
    this.sku,
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
          titleAr == other.titleAr &&
          titleEn == other.titleEn &&
          title == other.title &&
          nameAr == other.nameAr &&
          nameEn == other.nameEn &&
          name == other.name &&
          descriptionAr == other.descriptionAr &&
          descriptionEn == other.descriptionEn &&
          description == other.description &&
          price == other.price &&
          saleMode == other.saleMode &&
          imageUrl == other.imageUrl &&
          category == other.category &&
          brand == other.brand &&
          sku == other.sku &&
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
      titleAr.hashCode ^
      titleEn.hashCode ^
      title.hashCode ^
      nameAr.hashCode ^
      nameEn.hashCode ^
      name.hashCode ^
      descriptionAr.hashCode ^
      descriptionEn.hashCode ^
      description.hashCode ^
      price.hashCode ^
      saleMode.hashCode ^
      imageUrl.hashCode ^
      category.hashCode ^
      brand.hashCode ^
      sku.hashCode ^
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
    String? titleAr,
    String? titleEn,
    String? title,
    String? nameAr,
    String? nameEn,
    String? name,
    String? descriptionAr,
    String? descriptionEn,
    String? description,
    double? price,
    String? saleMode,
    String? imageUrl,
    String? category,
    String? brand,
    String? sku,
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
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      title: title ?? this.title,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      name: name ?? this.name,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      description: description ?? this.description,
      price: price ?? this.price,
      saleMode: saleMode ?? this.saleMode,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
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
      'title_ar': titleAr,
      'title_en': titleEn,
      'title': title,
      'name_ar': nameAr,
      'name_en': nameEn,
      'name': name,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'description': description,
      'price': price,
      'sale_mode': saleMode,
      'imageUrl': imageUrl,
      'category': category,
      'brand': brand,
      'sku': sku,
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
      userId: json['user_id'] != null
          ? int.tryParse(json['user_id'].toString())
          : null,
      titleAr: json['title_ar'] as String?,
      titleEn: json['title_en'] as String?,
      title: (json['title'] ?? json['title_en'] ?? json['title_ar']) as String?,
      nameAr: json['name_ar'] as String?,
      nameEn: json['name_en'] as String?,
      name: (json['name'] ?? json['name_en'] ?? json['name_ar']) as String?,
      descriptionAr: (json['description_ar'] ?? json['desc_ar']) as String?,
      descriptionEn: (json['description_en'] ?? json['desc_en']) as String?,
      description:
          (json['description'] ??
              json['description_en'] ??
              json['description_ar']) as String?,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      saleMode: (json['sale_mode'] ?? saleModeDirectPurchase).toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['image']) as String?,
      category: json['category'] as String?,
      brand: json['brand'] as String?,
      sku: json['sku'] as String?,
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
      images: () {
        final rawImages = json['images'];
        if (rawImages is Iterable) {
          return rawImages.map((item) => item.toString()).toList();
        }
        return null;
      }(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
