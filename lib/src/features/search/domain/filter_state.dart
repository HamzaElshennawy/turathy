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
  final String? denomination;
  final bool? isGraded;
  final String? gradingCompany;
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
    this.denomination,
    this.isGraded,
    this.gradingCompany,
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
          denomination == other.denomination &&
          isGraded == other.isGraded &&
          gradingCompany == other.gradingCompany &&
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
      denomination.hashCode ^
      isGraded.hashCode ^
      gradingCompany.hashCode ^
      gradeFrom.hashCode ^
      gradeTo.hashCode ^
      metalType.hashCode ^
      metalFineness.hashCode;

  @override
  String toString() {
    return 'FilterState{ selectedCategoryIndex: $selectedCategoryID, isAllOffersSelected: $isAllOffersSelected, searchText: $searchText, isLiveAuctionsSelected: $isLiveAuctionsSelected, auctionStatus: $auctionStatus, minPrice: $minPrice, maxPrice: $maxPrice, country: $country, dateFrom: $dateFrom, dateTo: $dateTo, denomination: $denomination, isGraded: $isGraded, gradingCompany: $gradingCompany, gradeFrom: $gradeFrom, gradeTo: $gradeTo, metalType: $metalType, metalFineness: $metalFineness}';
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
    String? denomination,
    bool? isGraded,
    String? gradingCompany,
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
      denomination: denomination == '' ? null : denomination ?? this.denomination,
      isGraded: isGraded ?? this.isGraded,
      gradingCompany: gradingCompany == '' ? null : gradingCompany ?? this.gradingCompany,
      gradeFrom: gradeFrom == -1 ? null : gradeFrom ?? this.gradeFrom,
      gradeTo: gradeTo == -1 ? null : gradeTo ?? this.gradeTo,
      metalType: metalType == '' ? null : metalType ?? this.metalType,
      metalFineness: metalFineness == '' ? null : metalFineness ?? this.metalFineness,
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
      if (country != null) 'country': country,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
      if (denomination != null) 'denomination': denomination,
      if (isGraded != null) 'is_graded': isGraded,
      if (gradingCompany != null) 'grading_company': gradingCompany,
      if (gradeFrom != null) 'grade_from': gradeFrom,
      if (gradeTo != null) 'grade_to': gradeTo,
      if (metalType != null) 'metal_type': metalType,
      if (metalFineness != null) 'metal_fineness': metalFineness,
    };
  }

  //</editor-fold>
}
