/// {@category Data}
///
/// Data repository for fetching and caching product categories.
/// 
/// This module provides the infrastructure for retrieving the full category 
/// taxonomy from the remote server and exposing it via a reactive Riverpod 
/// provider with a built-in refresh cycle.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../domain/category_model.dart';

/// Access layer for category-related network operations.
class CategoryRepository {
  /// Fetches the complete list of available categories from the backend.
  /// 
  /// Throws an [Exception] if the status code is not 200 or if the server 
  /// returns an error payload.
  static Future<List<CategoryModel>> getAllCategories() async {
    final result = await DioHelper.getData(
      url: EndPoints.allCategories, 
      token: CachedVariables.token,
    );
    
    if (result.statusCode == 200) {
      final List<CategoryModel> categories = [];
      // Logic: Extract lists from the standard 'data' envelope
      for (var item in result.data['data']) {
        categories.add(CategoryModel.fromJson(item));
      }
      return categories;
    } else {
      final String message =
          '${result.data['error']} in categories with code : ${result.statusCode}';
      throw Exception(message);
    }
  }
}

/// A reactive provider that fetches and periodically refreshes the category list.
/// 
/// Features:
/// - **Auto-Refresh**: Automatically invalidates itself every 3 minutes to 
///   ensure the home screen categories stay up to date.
/// - **Memory Management**: Cancels the refresh timer when the provider 
///   is disposed.
final getAllCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  // Logic: Set up a 3-minute staleness threshold
  final timer = Timer(const Duration(minutes: 3), () {
    ref.invalidateSelf();
  });
  
  ref.onDispose(() {
    timer.cancel(); // Cleanup to prevent memory leaks or background pings
  });
  
  return CategoryRepository.getAllCategories();
});
