import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../authintication/data/auth_repository.dart';
import '../domain/order_model.dart';
import '../utils/payment_debug_logger.dart';

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
        'items': order.items
            .map(
              (item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'address_id': order.addressId,
      };
    } else {
      data = Map<String, dynamic>.from(order.toJson())..remove('user_id');
    }

    PaymentDebugLogger.info('createOrder:request', data: {
      'url': url,
      'orderId': order.id,
      'userId': order.userId,
      'auctionId': order.auctionId,
      'addressId': order.addressId,
      'itemCount': order.items.length,
      'total': order.total,
      'isProductOrder': isProductOrder,
      'payload': data,
    });
    final result = await DioHelper.postData(
      url: url,
      token: CachedVariables.token,
      data: data,
    );
    if (result.statusCode == 201) {
      PaymentDebugLogger.info('createOrder:success', data: {
        'statusCode': result.statusCode,
        'response': result.data is Map
            ? Map<String, Object?>.from(result.data as Map)
            : {'response': result.data.toString()},
      });
      return OrderModel.fromJson(result.data['data']);
    } else {
      String message =
          result.data['error'] ?? 'An error occurred while creating the order';
      PaymentDebugLogger.error(
        'createOrder:failure',
        error: message,
        data: {
          'statusCode': result.statusCode,
          'response': result.data is Map
              ? Map<String, Object?>.from(result.data as Map)
              : {'response': result.data.toString()},
        },
      );
      throw AuthException(message, result.statusCode);
    }
  }

  Future<List<OrderModel>> getUserOrders(int userId) async {
    final result = await DioHelper.getData(
      url: EndPoints.getUserOrders,
      token: CachedVariables.token,
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
    PaymentDebugLogger.info('updateOrder:request', data: {
      'orderId': order.id,
      'addressId': order.addressId,
    });
    final result = await DioHelper.postData(
      url: EndPoints.baseUrl + 'order/update-order',
      token: CachedVariables.token,
      data: {
        'order_id': order.id,
        'address_id': order.addressId,
      },
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      PaymentDebugLogger.info('updateOrder:success', data: {
        'statusCode': result.statusCode,
        'response': result.data is Map
            ? Map<String, Object?>.from(result.data as Map)
            : {'response': result.data.toString()},
      });
      return OrderModel.fromJson(result.data['data']);
    } else {
      String message =
          result.data['error'] ?? 'An error occurred while updating the order';
      PaymentDebugLogger.error(
        'updateOrder:failure',
        error: message,
        data: {
          'statusCode': result.statusCode,
          'response': result.data is Map
              ? Map<String, Object?>.from(result.data as Map)
              : {'response': result.data.toString()},
        },
      );
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
    PaymentDebugLogger.info('uploadStoreReceipt:request', data: {
      'userId': userId,
      'orderId': orderId,
      'amount': amount,
      'fileName': fileName,
      'filePath': filePath,
    });

    final formData = FormData.fromMap({
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
      PaymentDebugLogger.info('uploadStoreReceipt:success', data: {
        'statusCode': response.statusCode,
        'response': response.data is Map
            ? Map<String, Object?>.from(response.data as Map)
            : {'response': response.data.toString()},
      });
      return OrderModel.fromJson(response.data['data']);
    } else {
      String message =
          response.data['error'] ?? 'An error occurred while uploading receipt';
      PaymentDebugLogger.error(
        'uploadStoreReceipt:failure',
        error: message,
        data: {
          'statusCode': response.statusCode,
          'response': response.data is Map
              ? Map<String, Object?>.from(response.data as Map)
              : {'response': response.data.toString()},
        },
      );
      throw AuthException(message, response.statusCode);
    }
  }

  Future<OrderModel> getTrustedOrderStatus(int orderId) async {
    PaymentDebugLogger.info('getTrustedOrderStatus:request', data: {
      'orderId': orderId,
      'url': EndPoints.getOrderPaymentStatus(orderId),
    });
    final response = await DioHelper.getData(
      url: EndPoints.getOrderPaymentStatus(orderId),
      token: CachedVariables.token,
    );

    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      PaymentDebugLogger.info('getTrustedOrderStatus:success', data: {
        'statusCode': response.statusCode,
        'data': data,
      });
      return OrderModel(
        id: data['orderId'] as int? ?? orderId,
        userId: data['userId'] as int? ?? 0,
        auctionId: 0,
        total: (data['total'] as num?)?.toDouble() ?? 0,
        date: DateTime.now(),
        pCs: 1,
        codAmt: '0',
        weight: '1',
        itemDesc: '',
        paymentStatus: data['paymentStatus'] as String?,
        orderStatus: data['orderStatus'] as String?,
        paymentId: data['paymentId'] as String?,
      );
    }

    final message =
        response.data['error'] ??
        'An error occurred while fetching the trusted order status';
    PaymentDebugLogger.error(
      'getTrustedOrderStatus:failure',
      error: message,
      data: {
        'statusCode': response.statusCode,
        'response': response.data is Map
            ? Map<String, Object?>.from(response.data as Map)
            : {'response': response.data.toString()},
      },
    );
    throw AuthException(message, response.statusCode);
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
