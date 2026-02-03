import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../home/data/category_repository.dart';
import '../../../../home/domain/category_model.dart';
import '../../../domain/filter_state.dart';

class FilterWidgetController extends StateNotifier<FilterState> {
  final List<String> colors = [
    '0xffFF0000'.toLowerCase(),
    '0xffFFA500'.toLowerCase(),
    '0xffFFFF00'.toLowerCase(),
    '0xff00FF00'.toLowerCase(),
    '0xff0000FF'.toLowerCase(),
    '0xff800080'.toLowerCase(),
    '0xffFFC0CB'.toLowerCase(),
    '0xffFFFFFF'.toLowerCase(),
    '0xff000000'.toLowerCase(),
    '0xff808080'.toLowerCase(),
    '0xffFFD700'.toLowerCase(),
    '0xffA52A2A'.toLowerCase(),
  ];
  final List<String> sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];
  final List<CategoryModel> categories;

  final TextEditingController searchController = TextEditingController();

  FilterWidgetController(this.categories) : super(FilterState());

  int get selectedColorIndex {
    return colors.indexOf(state.selectedColor ?? '');
  }

  int get selectedSizeIndex {
    return sizes.indexOf(state.selectedSize ?? '');
  }

  int get selectedCategoryIndex {
    return categories
        .indexWhere((element) => element.id == state.selectedCategoryID);
  }

  void selectColor(int index) {
    if (colors[index] == state.selectedColor) {
      state = state.copyWith(selectedColor: '');
    } else {
      state = state.copyWith(selectedColor: colors[index]);
    }
  }

  void selectSize(int index) {
    if (state.selectedSize == sizes[index]) {
      state = state.copyWith(selectedSize: '');
    } else {
      state = state.copyWith(selectedSize: sizes[index]);
    }
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
      ref.watch(getAllCategoriesProvider).value ?? []);
});
