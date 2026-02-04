import 'package:turathi/src/core/helper/dio/end_points.dart';

class CategoryModel {
  int? id;
  String? name;
  String? picUrl;
  String? createdAt;
  String? updatedAt;
  List<CategoryModel>? subCategories;

  CategoryModel({
    this.id,
    this.name,
    this.picUrl,
    this.createdAt,
    this.updatedAt,
    this.subCategories,
  });

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
