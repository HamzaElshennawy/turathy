import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../authintication/data/auth_repository.dart';
import '../domain/user_address_model.dart';

class AddressRepository {
  Future<List<UserAddressModel>> getUserAddresses(int userId) async {
    final result = await DioHelper.getData(
      url: EndPoints.getUserAddresses,
      token: CachedVariables.token,
      query: {'user_id': userId},
    );
    if (result.statusCode == 200) {
      final List data = result.data['data'] as List;
      return data.map((e) => UserAddressModel.fromJson(e)).toList();
    } else {
      final message =
          result.data['error'] ?? 'An error occurred while fetching addresses';
      throw AuthException(message.toString(), result.statusCode);
    }
  }

  Future<UserAddressModel> addAddress(Map<String, dynamic> dto) async {
    final result = await DioHelper.postData(
      url: EndPoints.addAddress,
      token: CachedVariables.token,
      data: dto,
    );
    if (result.statusCode == 201) {
      return UserAddressModel.fromJson(result.data['data']);
    } else {
      final message =
          result.data['error'] ?? 'An error occurred while adding address';
      throw AuthException(message.toString(), result.statusCode);
    }
  }

  Future<UserAddressModel> updateAddress(Map<String, dynamic> dto) async {
    final result = await DioHelper.postData(
      url: EndPoints.updateAddress,
      token: CachedVariables.token,
      data: dto,
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return UserAddressModel.fromJson(result.data['data']);
    } else {
      final message =
          result.data['error'] ?? 'An error occurred while updating address';
      throw AuthException(message.toString(), result.statusCode);
    }
  }

  Future<void> deleteAddress(int addressId) async {
    final result = await DioHelper.deleteData(
      url: EndPoints.deleteAddress,
      query: {'address_id': addressId},
      token: CachedVariables.token,
    );
    if (result.statusCode != 200) {
      final message =
          result.data['error'] ?? 'An error occurred while deleting address';
      throw AuthException(message.toString(), result.statusCode);
    }
  }
}

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository();
});

final userAddressesProvider = FutureProvider.autoDispose
    .family<List<UserAddressModel>, int>((ref, userId) async {
      return ref.watch(addressRepositoryProvider).getUserAddresses(userId);
    });
