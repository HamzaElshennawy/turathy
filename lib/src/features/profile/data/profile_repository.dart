import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../domain/address_model.dart';

class ProfileRepository {
  /// Update user profile fields (name, number, email, nickname, nationality)
  static Future<bool> updateUser({
    required int userId,
    String? name,
    String? number,
    String? email,
    String? nickname,
    String? nationality,
  }) async {
    final data = <String, dynamic>{'user_id': userId};
    if (name != null) data['name'] = name;
    if (number != null) data['number'] = number;
    if (email != null) data['email'] = email;
    if (nickname != null) data['nickname'] = nickname;
    if (nationality != null) data['nationality'] = nationality;

    final result = await DioHelper.putData(
      url: EndPoints.updateUser,
      data: data,
      token: CachedVariables.token,
    );

    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      debugPrint('updateUser error: ${result.statusCode} ${result.data}');
      return false;
    }
  }

  /// Get user addresses
  static Future<List<AddressModel>> getUserAddresses(int userId) async {
    final result = await DioHelper.getData(
      url: '${EndPoints.getUserAddresses}?user_id=$userId',
      token: CachedVariables.token,
    );

    if (result.statusCode == 200) {
      final list = result.data['data'] as List? ?? [];
      return list.map((e) => AddressModel.fromJson(e)).toList();
    }
    return [];
  }

  /// Add a new address
  static Future<AddressModel?> addAddress({
    required int userId,
    required String name,
    required String mobile,
    required String country,
    required String city,
    required String address,
    String? label,
    bool isDefault = false,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.addAddress,
      data: {
        'user_id': userId,
        'name': name,
        'mobile': mobile,
        'country': country,
        'city': city,
        'address': address,
        if (label != null) 'label': label,
        'isDefault': isDefault,
      },
      token: CachedVariables.token,
    );

    if (result.statusCode == 200 || result.statusCode == 201) {
      return AddressModel.fromJson(result.data['data']);
    }
    return null;
  }

  /// Delete an address
  static Future<bool> deleteAddress(int addressId) async {
    final result = await DioHelper.deleteData(
      url: '${EndPoints.deleteAddress}?address_id=$addressId',
      token: CachedVariables.token,
    );

    return result.statusCode == 200;
  }
}

/// Provider for user addresses list
final userAddressesProvider = FutureProvider.autoDispose<List<AddressModel>>((
  ref,
) async {
  final userId = CachedVariables.userId;
  if (userId == null) return [];
  return ProfileRepository.getUserAddresses(userId);
});
