import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../home/data/category_repository.dart';
import '../domain/filter_options_model.dart';
import '../presentation/widgets/filter_widget/filter_widget_controller.dart';

class FilterOptionsRepository {
  Future<FilterOptionsModel> getStoreFilterOptions({String? category}) async {
    final result = await DioHelper.getData(
      url: EndPoints.getProductFilterOptions,
      query: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );

    return FilterOptionsModel.fromJson(result.data['data'] ?? const {});
  }

  Future<FilterOptionsModel> getAuctionFilterOptions({
    required bool isLive,
    int? categoryId,
  }) async {
    final result = await DioHelper.getData(
      url: EndPoints.getAuctionFilterOptions,
      query: {
        'type': isLive ? 'Live' : 'Open',
        if (categoryId != null) 'category_id': categoryId,
      },
    );

    return FilterOptionsModel.fromJson(result.data['data'] ?? const {});
  }
}

final filterOptionsRepositoryProvider = Provider<FilterOptionsRepository>((ref) {
  return FilterOptionsRepository();
});

final storeFilterOptionsProvider = FutureProvider<FilterOptionsModel>((ref) async {
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

  return ref.watch(filterOptionsRepositoryProvider).getStoreFilterOptions(
        category: selectedCategoryName,
      );
});

final auctionFilterOptionsProvider = FutureProvider<FilterOptionsModel>((ref) async {
  final filters = ref.watch(filterWidgetControllerProvider);

  return ref.watch(filterOptionsRepositoryProvider).getAuctionFilterOptions(
        isLive: filters.isLiveAuctionsSelected,
        categoryId: filters.selectedCategoryID,
      );
});
