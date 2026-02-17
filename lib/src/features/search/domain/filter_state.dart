class FilterState {
  final int? selectedCategoryID;
  final bool isAllOffersSelected;
  final String? searchText;
  final bool isLiveAuctionsSelected;

  final String? auctionStatus;

  // New filters
  final double? minPrice;
  final double? maxPrice;
  final String? selectedCondition;
  final String? selectedAge;

  //<editor-fold desc="Data Methods">
  FilterState({
    this.selectedCategoryID,
    this.isAllOffersSelected = false,
    this.searchText,
    this.isLiveAuctionsSelected = false,
    this.auctionStatus,
    this.minPrice,
    this.maxPrice,
    this.selectedCondition,
    this.selectedAge,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilterState &&
          runtimeType == other.runtimeType &&
          selectedCategoryID == other.selectedCategoryID &&
          isAllOffersSelected == other.isAllOffersSelected &&
          searchText == other.searchText &&
          isLiveAuctionsSelected == other.isLiveAuctionsSelected &&
          auctionStatus == other.auctionStatus &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          selectedCondition == other.selectedCondition &&
          selectedAge == other.selectedAge);

  @override
  int get hashCode =>
      selectedCategoryID.hashCode ^
      isAllOffersSelected.hashCode ^
      searchText.hashCode ^
      isLiveAuctionsSelected.hashCode ^
      auctionStatus.hashCode ^
      minPrice.hashCode ^
      maxPrice.hashCode ^
      selectedCondition.hashCode ^
      selectedAge.hashCode;

  @override
  String toString() {
    return 'FilterState{ selectedCategoryIndex: $selectedCategoryID, isAllOffersSelected: $isAllOffersSelected, searchText: $searchText, isLiveAuctionsSelected: $isLiveAuctionsSelected, auctionStatus: $auctionStatus, minPrice: $minPrice, maxPrice: $maxPrice, selectedCondition: $selectedCondition, selectedAge: $selectedAge}';
  }

  FilterState copyWith({
    int? selectedCategoryID,
    bool? isAllOffersSelected,
    String? searchText,
    bool? isLiveAuctionsSelected,
    String? auctionStatus,
    double? minPrice,
    double? maxPrice,
    String? selectedCondition,
    String? selectedAge,
  }) {
    return FilterState(
      selectedCategoryID: selectedCategoryID == -1
          ? null
          : selectedCategoryID ?? this.selectedCategoryID,
      isAllOffersSelected: isAllOffersSelected ?? this.isAllOffersSelected,
      searchText: searchText ?? this.searchText,
      isLiveAuctionsSelected:
          isLiveAuctionsSelected ?? this.isLiveAuctionsSelected,
      auctionStatus: auctionStatus ?? this.auctionStatus,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedCondition: selectedCondition == ''
          ? null
          : selectedCondition ?? this.selectedCondition,
      selectedAge: selectedAge == '' ? null : selectedAge ?? this.selectedAge,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (selectedCategoryID != null) 'cat': selectedCategoryID,
      if (isAllOffersSelected) 'has_offer': '1',
      if (searchText != null) 'search': searchText,
      'type': isLiveAuctionsSelected ? 'Live' : 'Open',
      if (auctionStatus != null) 'status': auctionStatus,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (selectedCondition != null) 'condition': selectedCondition,
      if (selectedAge != null) 'age': selectedAge,
    };
  }

  //</editor-fold>
}
