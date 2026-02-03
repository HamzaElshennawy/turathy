import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../authintication/data/auth_repository.dart';
import '../domain/order_model.dart';

class OrderRepository {
  Future<OrderModel> createOrder(OrderModel order) async {
    final result = await DioHelper.postData(
      url: EndPoints.addOrder,
      token: CachedVariables.token,
      data: order.toJson(),
    );
    if (result.statusCode == 201) {
      return OrderModel.fromJson(result.data['data']);
    } else {
      String message = result.data['error'] ?? 'An error occurred while creating the order';
      throw AuthException(message, result.statusCode);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final createOrderProvider = FutureProvider.autoDispose.family<OrderModel, OrderModel>((ref, order) async {
  return ref.watch(orderRepositoryProvider).createOrder(order);
}); 