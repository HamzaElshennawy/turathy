class FilterState {
  final String? selectedColor;
  final String? selectedSize;
  final int? selectedCategoryID;
  final bool isAllOffersSelected;
  final String? searchText;
  final bool isLiveAuctionsSelected;

  final String? auctionStatus;

  //<editor-fold desc="Data Methods">
  FilterState({
    this.selectedColor,
    this.selectedSize,
    this.selectedCategoryID,
    this.isAllOffersSelected = false,
    this.searchText,
    this.isLiveAuctionsSelected = false,
    this.auctionStatus,
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
          isLiveAuctionsSelected == other.isLiveAuctionsSelected &&
          auctionStatus == other.auctionStatus);

  @override
  int get hashCode =>
      selectedColor.hashCode ^
      selectedSize.hashCode ^
      selectedCategoryID.hashCode ^
      isAllOffersSelected.hashCode ^
      searchText.hashCode ^
      isLiveAuctionsSelected.hashCode ^
      auctionStatus.hashCode;

  @override
  String toString() {
    return 'FilterState{ selectedColorIndex: $selectedColor, selectedSizeIndex: $selectedSize, selectedCategoryIndex: $selectedCategoryID, isAllOffersSelected: $isAllOffersSelected, searchText: $searchText, isLiveAuctionsSelected: $isLiveAuctionsSelected, auctionStatus: $auctionStatus}';
  }

  FilterState copyWith({
    String? selectedColor,
    String? selectedSize,
    int? selectedCategoryID,
    bool? isAllOffersSelected,
    String? searchText,
    bool? isLiveAuctionsSelected,
    String? auctionStatus,
  }) {
    return FilterState(
      selectedColor: selectedColor == ''
          ? null
          : selectedColor ?? this.selectedColor,
      selectedSize: selectedSize == ''
          ? null
          : selectedSize ?? this.selectedSize,
      selectedCategoryID: selectedCategoryID == -1
          ? null
          : selectedCategoryID ?? this.selectedCategoryID,
      isAllOffersSelected: isAllOffersSelected ?? this.isAllOffersSelected,
      searchText: searchText ?? this.searchText,
      isLiveAuctionsSelected:
          isLiveAuctionsSelected ?? this.isLiveAuctionsSelected,
      auctionStatus: auctionStatus ?? this.auctionStatus,
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
      if (auctionStatus != null) 'status': auctionStatus,
    };
  }

  //</editor-fold>
}
