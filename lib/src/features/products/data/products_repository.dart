import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/product_model.dart';

class ProductsRepository {
  Future<List<ProductModel>> getProducts() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    final String response = await rootBundle.loadString(
      'assets/json/products.json',
    );
    final List<dynamic> data = json.decode(response);
    return data.map((json) => ProductModel.fromJson(json)).toList();
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository();
});

final productsListProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productsRepositoryProvider).getProducts();
});
