import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/dio/dio_helper.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';
import 'dart:developer';

class FavoritesRepository {
  final Dio _dio = DioHelper.dio;

  Future<void> toggleLike({required int itemId, required String type}) async {
    try {
      await _dio.post(
        EndPoints.likes,
        data: {
          'itemId': itemId,
          'type': type,
          'userId': CachedVariables.userId,
        },
      );
    } catch (e) {
      log('Error toggling like: $e');
      rethrow;
    }
  }

  Future<List<ProductModel>> getLikedProducts() async {
    try {
      final response = await _dio.get(
        EndPoints.likedProducts,
        queryParameters: {'userId': CachedVariables.userId},
      );

      if (response.data['data'] == null) return [];

      final List<dynamic> data = response.data['data'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      log('Error getting liked products: $e');
      return [];
    }
  }

  Future<List<AuctionModel>> getLikedAuctions() async {
    try {
      final response = await _dio.get(
        EndPoints.likedAuctions,
        queryParameters: {'userId': CachedVariables.userId},
      );

      if (response.data['data'] == null) return [];

      final List<dynamic> data = response.data['data'];
      return data.map((json) => AuctionModel.fromJson(json)).toList();
    } catch (e) {
      log('Error getting liked auctions: $e');
      return [];
    }
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});
