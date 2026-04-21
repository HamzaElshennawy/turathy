class FilterState {
  final int? selectedCategoryID;
  final bool isAllOffersSelected;
  final String? searchText;
  final bool isLiveAuctionsSelected;

  final String? auctionStatus;

  // New filters
  final double? minPrice;
  final double? maxPrice;
  
  // 10 new filters
  final String? country;
  final int? dateFrom;
  final int? dateTo;
  final String? itemType;
  final String? denomination;
  final bool? isGraded;
  final String? gradingCompany;
  final String? gradeDesignation;
  final int? gradeFrom;
  final int? gradeTo;
  final String? metalType;
  final String? metalFineness;

  //<editor-fold desc="Data Methods">
  FilterState({
    this.selectedCategoryID,
    this.isAllOffersSelected = false,
    this.searchText,
    this.isLiveAuctionsSelected = false,
    this.auctionStatus,
    this.minPrice,
    this.maxPrice,
    this.country,
    this.dateFrom,
    this.dateTo,
    this.itemType,
    this.denomination,
    this.isGraded,
    this.gradingCompany,
    this.gradeDesignation,
    this.gradeFrom,
    this.gradeTo,
    this.metalType,
    this.metalFineness,
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
          country == other.country &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo &&
          itemType == other.itemType &&
          denomination == other.denomination &&
          isGraded == other.isGraded &&
          gradingCompany == other.gradingCompany &&
          gradeDesignation == other.gradeDesignation &&
          gradeFrom == other.gradeFrom &&
          gradeTo == other.gradeTo &&
          metalType == other.metalType &&
          metalFineness == other.metalFineness);

  @override
  int get hashCode =>
      selectedCategoryID.hashCode ^
      isAllOffersSelected.hashCode ^
      searchText.hashCode ^
      isLiveAuctionsSelected.hashCode ^
      auctionStatus.hashCode ^
      minPrice.hashCode ^
      maxPrice.hashCode ^
      country.hashCode ^
      dateFrom.hashCode ^
      dateTo.hashCode ^
      itemType.hashCode ^
      denomination.hashCode ^
      isGraded.hashCode ^
      gradingCompany.hashCode ^
      gradeDesignation.hashCode ^
      gradeFrom.hashCode ^
      gradeTo.hashCode ^
      metalType.hashCode ^
      metalFineness.hashCode;

  @override
  String toString() {
    return 'FilterState{ selectedCategoryIndex: $selectedCategoryID, isAllOffersSelected: $isAllOffersSelected, searchText: $searchText, isLiveAuctionsSelected: $isLiveAuctionsSelected, auctionStatus: $auctionStatus, minPrice: $minPrice, maxPrice: $maxPrice, country: $country, dateFrom: $dateFrom, dateTo: $dateTo, itemType: $itemType, denomination: $denomination, isGraded: $isGraded, gradingCompany: $gradingCompany, gradeDesignation: $gradeDesignation, gradeFrom: $gradeFrom, gradeTo: $gradeTo, metalType: $metalType, metalFineness: $metalFineness}';
  }

  FilterState copyWith({
    int? selectedCategoryID,
    bool? isAllOffersSelected,
    String? searchText,
    bool? isLiveAuctionsSelected,
    String? auctionStatus,
    double? minPrice,
    double? maxPrice,
    String? country,
    int? dateFrom,
    int? dateTo,
    String? itemType,
    String? denomination,
    bool? isGraded,
    String? gradingCompany,
    String? gradeDesignation,
    int? gradeFrom,
    int? gradeTo,
    String? metalType,
    String? metalFineness,
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
      country: country == '' ? null : country ?? this.country,
      dateFrom: dateFrom == -1 ? null : dateFrom ?? this.dateFrom,
      dateTo: dateTo == -1 ? null : dateTo ?? this.dateTo,
      itemType: itemType == '' ? null : itemType ?? this.itemType,
      denomination: denomination == '' ? null : denomination ?? this.denomination,
      isGraded: isGraded ?? this.isGraded,
      gradingCompany: gradingCompany == '' ? null : gradingCompany ?? this.gradingCompany,
      gradeDesignation: gradeDesignation == '' ? null : gradeDesignation ?? this.gradeDesignation,
      gradeFrom: gradeFrom == -1 ? null : gradeFrom ?? this.gradeFrom,
      gradeTo: gradeTo == -1 ? null : gradeTo ?? this.gradeTo,
      metalType: metalType == '' ? null : metalType ?? this.metalType,
      metalFineness: metalFineness == '' ? null : metalFineness ?? this.metalFineness,
    );
  }

  Map<String, dynamic> toAuctionQuery() {
    return {
      if (selectedCategoryID != null) 'cat': selectedCategoryID,
      if (isAllOffersSelected) 'has_offer': '1',
      if (searchText != null) 'search': searchText,
      'type': isLiveAuctionsSelected ? 'Live' : 'Open',
      if (auctionStatus != null) 'status': auctionStatus,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (country != null) 'country': country,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
      if (itemType != null) 'item_type': itemType,
      if (denomination != null) 'denomination': denomination,
      if (isGraded != null) 'is_graded': isGraded,
      if (gradingCompany != null) 'grading_company': gradingCompany,
      if (gradeDesignation != null) 'grade_designation': gradeDesignation,
      if (gradeFrom != null) 'grade_from': gradeFrom,
      if (gradeTo != null) 'grade_to': gradeTo,
      if (metalType != null) 'metal_type': metalType,
      if (metalFineness != null) 'metal_fineness': metalFineness,
    };
  }

  Map<String, dynamic> toProductQuery({String? categoryName}) {
    return {
      if (searchText != null) 'search': searchText,
      if (categoryName != null && categoryName.isNotEmpty) 'category': categoryName,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (country != null) 'country': country,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      if (itemType != null) 'itemType': itemType,
      if (denomination != null) 'denomination': denomination,
      if (isGraded != null) 'isGraded': isGraded,
      if (gradingCompany != null) 'gradingCompany': gradingCompany,
      if (gradeDesignation != null) 'gradeDesignation': gradeDesignation,
      if (gradeFrom != null) 'gradeFrom': gradeFrom,
      if (gradeTo != null) 'gradeTo': gradeTo,
      if (metalType != null) 'metalType': metalType,
      if (metalFineness != null) 'metalFineness': metalFineness,
    };
  }

  //</editor-fold>
}
