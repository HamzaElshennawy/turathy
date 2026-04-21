import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../home/data/category_repository.dart';
import '../../../../home/domain/category_model.dart';
import '../../../domain/filter_state.dart';

class FilterWidgetController extends StateNotifier<FilterState> {
  final List<CategoryModel> categories;

  final TextEditingController searchController = TextEditingController();

  FilterWidgetController(this.categories) : super(FilterState());

  int get selectedCategoryIndex {
    return categories.indexWhere(
      (element) => element.id == state.selectedCategoryID,
    );
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

  void setSearchText(String text) {
    if (state.searchText == text) return;
    state = state.copyWith(searchText: text);
  }

  void setIsLiveAuctionsSelected(bool value) {
    state = state.copyWith(isLiveAuctionsSelected: value);
  }

  void setCountry(String text) {
    state = state.copyWith(country: text.isEmpty ? '' : text);
  }

  void setDateFrom(int? year) {
    state = state.copyWith(dateFrom: year ?? -1);
  }

  void setDateTo(int? year) {
    state = state.copyWith(dateTo: year ?? -1);
  }

  void setDenomination(String text) {
    state = state.copyWith(denomination: text.isEmpty ? '' : text);
  }

  void setItemType(String text) {
    state = state.copyWith(itemType: text.isEmpty ? '' : text);
  }

  void setIsGraded(bool? value) {
    if (value == false) {
      state = state.copyWith(
        isGraded: value,
        gradingCompany: '',
        gradeDesignation: '',
        gradeFrom: -1,
        gradeTo: -1,
      );
    } else if (value == null) {
      state = state.copyWith(
        isGraded: null,
        gradingCompany: '',
        gradeDesignation: '',
        gradeFrom: -1,
        gradeTo: -1,
      );
    } else {
      state = state.copyWith(isGraded: value);
    }
  }

  void setGradingCompany(String value) {
    state = state.copyWith(gradingCompany: value.isEmpty ? '' : value);
  }

  void setGradeDesignation(String text) {
    state = state.copyWith(gradeDesignation: text.isEmpty ? '' : text);
  }

  void setGradeFrom(int? grade) {
    state = state.copyWith(gradeFrom: grade ?? -1);
  }

  void setGradeTo(int? grade) {
    state = state.copyWith(gradeTo: grade ?? -1);
  }

  void setMetalType(String text) {
    state = state.copyWith(metalType: text.isEmpty ? '' : text);
  }

  void setMetalFineness(String text) {
    state = state.copyWith(metalFineness: text.isEmpty ? '' : text);
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
