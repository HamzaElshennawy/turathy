import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/dio/dio_helper.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';

import '../domain/preorder_request_model.dart';

class PreorderRepository {
  Future<PreorderRequestModel> getCurrentRequest() async {
    final result = await DioHelper.getData(
      url: EndPoints.preorderCurrent,
      token: CachedVariables.token,
    );
    if (result.statusCode == 200) {
      return PreorderRequestModel.fromJson(
        result.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load preorder list');
  }

  Future<PreorderRequestModel> addItem(int productId, {int quantity = 1}) async {
    final result = await DioHelper.postData(
      url: EndPoints.preorderAddItem,
      token: CachedVariables.token,
      data: {'product_id': productId, 'quantity': quantity},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return PreorderRequestModel.fromJson(
        result.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to add preorder item');
  }

  Future<PreorderRequestModel> updateQuantity(int productId, int quantity) async {
    final result = await DioHelper.patchData(
      url: EndPoints.preorderUpdateQuantity(productId, quantity),
      token: CachedVariables.token,
      data: const {},
    );
    if (result.statusCode == 200) {
      return PreorderRequestModel.fromJson(
        result.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to update preorder quantity');
  }

  Future<PreorderRequestModel> removeItem(int productId) async {
    final result = await DioHelper.deleteData(
      url: EndPoints.preorderRemoveItem(productId),
      token: CachedVariables.token,
    );
    if (result.statusCode == 200) {
      return PreorderRequestModel.fromJson(
        result.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to remove preorder item');
  }

  Future<PreorderRequestModel> submitRequest({String? notes}) async {
    final result = await DioHelper.postData(
      url: EndPoints.preorderSubmit,
      token: CachedVariables.token,
      data: {'notes': notes},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return PreorderRequestModel.fromJson(
        result.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to submit preorder request');
  }
}

final preorderRepositoryProvider = Provider<PreorderRepository>(
  (ref) => PreorderRepository(),
);

final currentPreorderProvider = FutureProvider<PreorderRequestModel>((ref) async {
  return ref.watch(preorderRepositoryProvider).getCurrentRequest();
});
