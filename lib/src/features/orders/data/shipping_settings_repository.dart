import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import '../domain/shipping_setting_model.dart';

final shippingSettingsRepositoryProvider = Provider(
  (ref) => ShippingSettingsRepository(),
);

class ShippingSettingsRepository {
  Future<List<ShippingSettingModel>> getShippingSettings() async {
    try {
      final token = CachedVariables.token;
      final headers = {'Content-Type': 'application/json'};

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('${EndPoints.baseUrl}/shipping-settings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['data'] ?? [];
        return data.map((json) => ShippingSettingModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shipping settings');
      }
    } catch (e) {
      throw Exception('Failed to load shipping settings: $e');
    }
  }
}
