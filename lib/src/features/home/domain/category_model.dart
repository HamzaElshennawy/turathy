/// {@category Domain}
///
/// Data model representing a product category in the Turathy marketplace.
/// 
/// [CategoryModel] supports a recursive hierarchy (sub-categories) and 
/// automatically handles full-path resolution for category icons/images.
library;

import '../../../core/helper/dio/end_points.dart';

/// A structural representation of an item category.
class CategoryModel {
  /// Unique identifier from the backend.
  int? id;

  /// The human-readable name of the category (e.g., "Antiques").
  String? name;

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
    this.name,
    this.picUrl,
    this.createdAt,
    this.updatedAt,
    this.subCategories,
  });

  /// Factory constructor to hydrate a [CategoryModel] from a JSON map.
  /// 
  /// **Logic Note**: If `pic_url` is present, it is automatically prefixed 
  /// with [EndPoints.baseUrl] to create a valid network address.
  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
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
    data['name'] = name;
    data['pic_url'] = picUrl;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    if (subCategories != null) {
      data['subCategories'] = subCategories!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
