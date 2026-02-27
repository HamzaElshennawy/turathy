import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../authintication/data/auth_repository.dart';
import '../domain/order_model.dart';

class OrderRepository {
  Future<OrderModel> createOrder(OrderModel order) async {
    final bool isProductOrder =
        (order.productId != null && order.productId != 0) &&
        (order.auctionId == 0);
    final String url = isProductOrder
        ? EndPoints.addProductOrder
        : EndPoints.addOrder;

    Map<String, dynamic> data;
    if (isProductOrder) {
      data = {
        'user_id': order.userId,
        'product_id': order.productId,
        'quantity': order.pCs,
        'address_id': order.addressId,
      };
    } else {
      data = order.toJson();
    }

    final result = await DioHelper.postData(
      url: url,
      token: CachedVariables.token,
      data: data,
    );
    if (result.statusCode == 201) {
      return OrderModel.fromJson(result.data['data']);
    } else {
      String message =
          result.data['error'] ?? 'An error occurred while creating the order';
      throw AuthException(message, result.statusCode);
    }
  }

  Future<List<OrderModel>> getUserOrders(int userId) async {
    final result = await DioHelper.getData(
      url: EndPoints.getUserOrders,
      token: CachedVariables.token,
      query: {'user_id': userId, 'include': 'user_addresses'},
    );
    if (result.statusCode == 200) {
      List<OrderModel> orders = [];
      for (var item in result.data['data']) {
        orders.add(OrderModel.fromJson(item));
      }
      return orders;
    } else {
      String message =
          result.data['error'] ??
          'An error occurred while fetching user orders';
      throw AuthException(message, result.statusCode);
    }
  }

  Future<OrderModel> updateOrder(OrderModel order) async {
    final result = await DioHelper.postData(
      url: EndPoints.baseUrl + 'order/update-order',
      token: CachedVariables.token,
      data: {...order.toJson(), 'order_id': order.id},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return OrderModel.fromJson(result.data['data']);
    } else {
      String message =
          result.data['error'] ?? 'An error occurred while updating the order';
      throw AuthException(message, result.statusCode);
    }
  }

  Future<OrderModel> uploadStoreReceipt({
    required int userId,
    required int orderId,
    required int amount,
    required String filePath,
  }) async {
    final String fileName = filePath.split('/').last.split('\\').last;

    final formData = FormData.fromMap({
      'user_id': userId,
      'order_id': orderId,
      'amount': amount,
      'receipt': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await DioHelper.postData(
      url: EndPoints.uploadStoreReceipt,
      data: formData,
      token: CachedVariables.token,
      isMultipart: true,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return OrderModel.fromJson(response.data['data']);
    } else {
      String message =
          response.data['error'] ?? 'An error occurred while uploading receipt';
      throw AuthException(message, response.statusCode);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final createOrderProvider = FutureProvider.autoDispose
    .family<OrderModel, OrderModel>((ref, order) async {
      return ref.watch(orderRepositoryProvider).createOrder(order);
    });

final updateOrderProvider = FutureProvider.autoDispose
    .family<OrderModel, OrderModel>((ref, order) async {
      return ref.watch(orderRepositoryProvider).updateOrder(order);
    });

final getUserOrdersProvider = FutureProvider.autoDispose
    .family<List<OrderModel>, int>((ref, userId) async {
      return ref.watch(orderRepositoryProvider).getUserOrders(userId);
    });
