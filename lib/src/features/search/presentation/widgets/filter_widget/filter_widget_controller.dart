import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../home/data/category_repository.dart';
import '../../../../home/domain/category_model.dart';
import '../../../domain/filter_state.dart';

class FilterWidgetController extends StateNotifier<FilterState> {
  final List<String> ages = [
    AppStrings.lessThan10Years.tr(),
    AppStrings.tenToFiftyYears.tr(),
    AppStrings.plus50Years.tr(),
  ];
  final List<String> conditions = [
    AppStrings.newCondition.tr(),
    AppStrings.usedCondition.tr(),
    AppStrings.antiqueCondition.tr(),
  ];
  final List<CategoryModel> categories;

  final TextEditingController searchController = TextEditingController();

  FilterWidgetController(this.categories) : super(FilterState());

  int get selectedAgeIndex {
    return ages.indexOf(state.selectedAge ?? '');
  }

  int get selectedConditionIndex {
    return conditions.indexOf(state.selectedCondition ?? '');
  }

  int get selectedCategoryIndex {
    return categories.indexWhere(
      (element) => element.id == state.selectedCategoryID,
    );
  }

  void selectAge(int index) {
    if (ages[index] == state.selectedAge) {
      state = state.copyWith(selectedAge: '');
    } else {
      state = state.copyWith(selectedAge: ages[index]);
    }
  }

  void selectCondition(int index) {
    if (state.selectedCondition == conditions[index]) {
      state = state.copyWith(selectedCondition: '');
    } else {
      state = state.copyWith(selectedCondition: conditions[index]);
    }
  }

  void setMinPrice(double? price) {
    state = state.copyWith(minPrice: price);
  }

  void setMaxPrice(double? price) {
    state = state.copyWith(maxPrice: price);
  }

  void selectCategory(int index) {
    if (state.selectedCategoryID == categories[index].id) {
      state = state.copyWith(selectedCategoryID: -1);
    } else {
      state = state.copyWith(selectedCategoryID: categories[index].id);
    }
  }

  void selectAllOffers() {
    state = state.copyWith(isAllOffersSelected: !state.isAllOffersSelected);
  }

  void setSearchText(String text) {
    if (state.searchText == text) return;
    state = state.copyWith(searchText: text);
  }

  void setIsLiveAuctionsSelected(bool value) {
    state = state.copyWith(isLiveAuctionsSelected: value);
  }

  void clearFilters() {
    state = FilterState();
    searchController.clear();
  }
}

final filterWidgetControllerProvider =
    StateNotifierProvider<FilterWidgetController, FilterState>((ref) {
      return FilterWidgetController(
        ref.watch(getAllCategoriesProvider).value ?? [],
      );
    });
