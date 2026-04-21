import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../../home/data/category_repository.dart';
import '../domain/product_model.dart';
import '../../search/domain/filter_state.dart';
import '../../search/presentation/widgets/filter_widget/filter_widget_controller.dart';

class ProductsRepository {
  final Dio _dio = DioHelper.dio;

  Future<List<ProductModel>> getProducts() async {
    final response = await _dio.get(EndPoints.getProducts);
    final rawData = response.data['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }
    return rawData.map((json) => ProductModel.fromJson(json)).toList();
  }

  Future<List<ProductModel>> getFilteredProducts(
    FilterState filters, {
    String? categoryName,
  }) async {
    final response = await _dio.get(
      EndPoints.getProducts,
      queryParameters: filters.toProductQuery(categoryName: categoryName),
    );
    final rawData = response.data['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }
    return rawData.map((json) => ProductModel.fromJson(json)).toList();
  }

  Future<ProductModel> getProduct(int productId) async {
    final response = await _dio.get(
      EndPoints.getProduct,
      queryParameters: {'product_id': productId},
    );
    return ProductModel.fromJson(response.data['data']);
  }

  Future<ProductModel> addProduct(
    Map<String, dynamic> productData,
    List<dynamic> images,
  ) async {
    FormData formData = FormData.fromMap(productData);

    for (var image in images) {
      if (image != null) {
        String fileName = image.path.split('/').last;
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(image.path, filename: fileName),
          ),
        );
      }
    }

    final response = await _dio.post(
      EndPoints.addProduct,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    return ProductModel.fromJson(response.data['data']);
  }

  Future<List<ProductModel>> getMyProducts() async {
    final response = await _dio.get(
      EndPoints.getUserProducts,
      queryParameters: {'user_id': CachedVariables.userId ?? 0},
      options: Options(
        headers: {'Authorization': 'Bearer ${CachedVariables.token}'},
      ),
    );
    final rawData = response.data['data'];
    if (rawData == null || rawData is! List) {
      return [];
    }
    return rawData.map((json) => ProductModel.fromJson(json)).toList();
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository();
});

final productsListProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productsRepositoryProvider).getProducts();
});

final filteredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final filters = ref.watch(filterWidgetControllerProvider);
  final categories = await ref.watch(getAllCategoriesProvider.future);

  String? selectedCategoryName;
  if (filters.selectedCategoryID != null) {
    for (final category in categories) {
      if (category.id == filters.selectedCategoryID) {
        selectedCategoryName = category.name;
        break;
      }
    }
  }

  return ref.watch(productsRepositoryProvider).getFilteredProducts(
        filters,
        categoryName: selectedCategoryName,
      );
});

final myProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(productsRepositoryProvider).getMyProducts();
});

final productDetailsProvider = FutureProvider.family<ProductModel, int>((
  ref,
  productId,
) async {
  return ref.watch(productsRepositoryProvider).getProduct(productId);
});
