import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/dio/dio_helper.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';

class SearchRepository {
  Future<List<dynamic>> search(String query) async {
    try {
      final response = await DioHelper.getData(
        url: EndPoints.search,
        query: {'q': query},
      );
      log(response.data.toString());
      List<dynamic> data;
      if (response.data is Map && response.data.containsKey('data')) {
        data = response.data['data'];
      } else if (response.data is List) {
        data = response.data;
      } else {
        log('Invalid response format: ${response.data}');
        data = [];
      }
      log('Search Response Data: $data');
      final List<dynamic> results = [];

      for (var item in data) {
        try {
          if (item['type'] == 'product') {
            results.add(ProductModel.fromJson(item));
          } else if (item['type'] == 'auction') {
            // Fix for AuctionModel expecting 'type' to be 'Live' or 'Public'
            // The search endpoint overwrites 'type' to 'auction'.
            // We rely on 'isLive' boolean if available, or default to generic.
            if (item['isLive'] == true) {
              item['type'] = 'Live';
            } else {
              // Fallback or check other fields. Assuming non-live if isLive is false/null
              item['type'] = 'Public';
            }

            results.add(AuctionModel.fromJson(item));
          }
        } catch (e) {
          log('Error parsing search item: $e');
          log('Item data: $item');
        }
      }

      return results;
    } catch (e) {
      // In a real app, we might want to return an empty list or rethrow custom exception
      throw Exception('Failed to search: $e');
    }
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});
