import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../domain/category_model.dart';

class CategoryRepository {
  static Future<List<CategoryModel>> getAllCategories() async {
    final result = await DioHelper.getData(
        url: EndPoints.allCategories, token: CachedVariables.token);
    if (result.statusCode == 200) {
      List<CategoryModel> categories = [];
      for (var item in result.data['data']) {
        categories.add(CategoryModel.fromJson(item));
      }
      return categories;
    } else {
      String message =
          '${result.data['error']} in categories with code : ${result.statusCode}';
      throw Exception(message);
    }
  }
}

final getAllCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final timer = Timer(const Duration(minutes: 3), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
  });
  return CategoryRepository.getAllCategories();
});
