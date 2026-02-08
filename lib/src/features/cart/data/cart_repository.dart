import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../domain/cart_model.dart';

class CartRepository {
  Future<List<CartItemModel>> getCart(int userId) async {
    final result = await DioHelper.getData(
      url: '${EndPoints.cart}/$userId',
      token: CachedVariables.token,
    );
    if (result.statusCode == 200) {
      final List<dynamic> data = result.data['data'] as List<dynamic>;
      return data
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load cart');
  }

  Future<CartItemModel> addToCart(
    int userId,
    int productId, {
    int quantity = 1,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.cartAdd,
      token: CachedVariables.token,
      data: {'user_id': userId, 'product_id': productId, 'quantity': quantity},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return CartItemModel.fromJson(
        result.data['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to add to cart');
  }

  Future<void> removeFromCart(int userId, int productId) async {
    final result = await DioHelper.deleteData(
      url: EndPoints.cartRemove,
      token: CachedVariables.token,
      data: {'user_id': userId, 'product_id': productId},
    );
    if (result.statusCode != 200) {
      throw Exception('Failed to remove from cart');
    }
  }

  Future<void> clearCart(int userId) async {
    final result = await DioHelper.deleteData(
      url: '${EndPoints.cartClear}/$userId',
      token: CachedVariables.token,
    );
    if (result.statusCode != 200) {
      throw Exception('Failed to clear cart');
    }
  }
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(),
);

final cartProvider = FutureProvider.family<List<CartItemModel>, int>((
  ref,
  userId,
) async {
  return ref.watch(cartRepositoryProvider).getCart(userId);
});
