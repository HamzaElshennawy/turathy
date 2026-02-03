class FilterState {
  final String? selectedColor;
  final String? selectedSize;
  final int? selectedCategoryID;
  final bool isAllOffersSelected;
  final String? searchText;
  final bool isLiveAuctionsSelected;

//<editor-fold desc="Data Methods">
  FilterState({
    this.selectedColor,
    this.selectedSize,
    this.selectedCategoryID,
    this.isAllOffersSelected = false,
    this.searchText,
    this.isLiveAuctionsSelected = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilterState &&
          runtimeType == other.runtimeType &&
          selectedColor == other.selectedColor &&
          selectedSize == other.selectedSize &&
          selectedCategoryID == other.selectedCategoryID &&
          isAllOffersSelected == other.isAllOffersSelected &&
          searchText == other.searchText &&
          isLiveAuctionsSelected == other.isLiveAuctionsSelected);

  @override
  int get hashCode =>
      selectedColor.hashCode ^
      selectedSize.hashCode ^
      selectedCategoryID.hashCode ^
      isAllOffersSelected.hashCode ^
      searchText.hashCode ^
      isLiveAuctionsSelected.hashCode;

  @override
  String toString() {
    return 'FilterState{ selectedColorIndex: $selectedColor, selectedSizeIndex: $selectedSize, selectedCategoryIndex: $selectedCategoryID, isAllOffersSelected: $isAllOffersSelected, searchText: $searchText, isLiveAuctionsSelected: $isLiveAuctionsSelected}';
  }

  FilterState copyWith({
    String? selectedColor,
    String? selectedSize,
    int? selectedCategoryID,
    bool? isAllOffersSelected,
    String? searchText,
    bool? isLiveAuctionsSelected,
  }) {
    return FilterState(
      selectedColor:
          selectedColor == '' ? null : selectedColor ?? this.selectedColor,
      selectedSize:
          selectedSize == '' ? null : selectedSize ?? this.selectedSize,
      selectedCategoryID: selectedCategoryID == -1
          ? null
          : selectedCategoryID ?? this.selectedCategoryID,
      isAllOffersSelected: isAllOffersSelected ?? this.isAllOffersSelected,
      searchText: searchText ?? this.searchText,
      isLiveAuctionsSelected:
          isLiveAuctionsSelected ?? this.isLiveAuctionsSelected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (selectedColor != null) 'color': selectedColor,
      if (selectedSize != null) 'size': selectedSize,
      if (selectedCategoryID != null) 'cat': selectedCategoryID,
      if (isAllOffersSelected) 'has_offer': '1',
      if (searchText != null) 'search': searchText,
      'type': isLiveAuctionsSelected ? 'Live' : 'Open',
    };
  }

//</editor-fold>
}
