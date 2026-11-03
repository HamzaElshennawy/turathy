/// {@category Domain}
///
/// Data model representing a product category in the Turathy marketplace.
/// 
/// [CategoryModel] supports a recursive hierarchy (sub-categories) and 
/// automatically handles full-path resolution for category icons/images.
/// Supports bilingual names (Arabic/English) via [nameAr] and [nameEn].
library;

import '../../../core/helper/dio/end_points.dart';
import '../../products/domain/product_model.dart';
import '../../search/domain/filter_state.dart';

/// A structural representation of an item category.
class CategoryModel {
  /// Unique identifier from the backend.
  int? id;

  /// Arabic name of the category.
  String? nameAr;

  /// English name of the category.
  String? nameEn;

  /// Backward-compatible getter — returns Arabic name as default.
  String? get name => nameAr;

  /// Returns the localized category name for the given [locale] code.
  /// 
  /// Falls back to the other language if the preferred one is not available.
  String localizedName(String locale) =>
      locale == 'ar' ? (nameAr ?? nameEn ?? '') : (nameEn ?? nameAr ?? '');

  /// Normalized absolute URL to the category's thumbnail/icon.
  String? picUrl;

  /// Timestamp of creation on the server.
  String? createdAt;

  /// Timestamp of the last modification on the server.
  String? updatedAt;

  /// A list of child categories belonging to this parent.
  List<CategoryModel>? subCategories;

  /// Standard constructor for manual instantiation.
  CategoryModel({
    this.id,
    this.nameAr,
    this.nameEn,
    this.picUrl,
    this.createdAt,
    this.updatedAt,
    this.subCategories,
  });

  /// Factory constructor to hydrate a [CategoryModel] from a JSON map.
  /// 
  /// **Logic Note**: If `pic_url` is present, it is automatically prefixed 
  /// with [EndPoints.baseUrl] to create a valid network address.
  /// Reads `name_ar` and `name_en` fields, with fallback to legacy `name` field.
  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nameAr = json['name_ar'] ?? json['name'];
    nameEn = json['name_en'];
    picUrl = json['pic_url'] != null ? EndPoints.baseUrl + json['pic_url'] : '';
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    if (json['subCategories'] != null) {
      subCategories = <CategoryModel>[];
      json['subCategories'].forEach((v) {
        subCategories!.add(CategoryModel.fromJson(v));
      });
    }
  }

  /// Exports the model instance back into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name_ar'] = nameAr;
    data['name_en'] = nameEn;
    data['pic_url'] = picUrl;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    if (subCategories != null) {
      data['subCategories'] = subCategories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// Store rows keep a free-text category. Match either catalog name.
bool productCategoryMatches(String? productCategory, CategoryModel category) {
  final value = (productCategory ?? '').trim().toLowerCase();
  if (value.isEmpty) return false;
  bool same(String? name) {
    final normalized = (name ?? '').trim().toLowerCase();
    return normalized.isNotEmpty && normalized == value;
  }
  return same(category.nameAr) || same(category.nameEn);
}

/// In-memory store filter. Avoids a full catalog download on every chip or keystroke.
bool productMatchesStoreFilters(
  ProductModel product,
  FilterState filters,
  CategoryModel? category,
) {
  if (category != null && !productCategoryMatches(product.category, category)) {
    return false;
  }
  final query = (filters.searchText ?? '').trim().toLowerCase();
  if (query.isNotEmpty) {
    final haystack = [
      product.title,
      product.titleAr,
      product.titleEn,
      product.name,
      product.nameAr,
      product.nameEn,
    ].whereType<String>().join(' ').toLowerCase();
    if (!haystack.contains(query)) return false;
  }
  final price = product.price ?? 0;
  if (filters.minPrice != null && price < filters.minPrice!) return false;
  if (filters.maxPrice != null && price > filters.maxPrice!) return false;
  return true;
}
