class FilterOptionsModel {
  final List<String> countries;
  final List<String> itemTypes;
  final List<String> denominations;
  final List<String> gradingCompanies;
  final List<String> gradeDesignations;
  final List<String> metalTypes;
  final List<String> metalFinenessValues;
  final double? minPrice;
  final double? maxPrice;
  final int? minYear;
  final int? maxYear;
  final int? minGrade;
  final int? maxGrade;

  const FilterOptionsModel({
    this.countries = const [],
    this.itemTypes = const [],
    this.denominations = const [],
    this.gradingCompanies = const [],
    this.gradeDesignations = const [],
    this.metalTypes = const [],
    this.metalFinenessValues = const [],
    this.minPrice,
    this.maxPrice,
    this.minYear,
    this.maxYear,
    this.minGrade,
    this.maxGrade,
  });

  factory FilterOptionsModel.fromJson(Map<String, dynamic> json) {
    List<String> readList(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw.map((item) => item.toString()).toList();
    }

    return FilterOptionsModel(
      countries: readList('countries'),
      itemTypes: readList('item_types'),
      denominations: readList('denominations'),
      gradingCompanies: readList('grading_companies'),
      gradeDesignations: readList('grade_designations'),
      metalTypes: readList('metal_types'),
      metalFinenessValues: readList('metal_fineness_values'),
      minPrice: json['min_price'] != null
          ? double.tryParse(json['min_price'].toString())
          : null,
      maxPrice: json['max_price'] != null
          ? double.tryParse(json['max_price'].toString())
          : null,
      minYear:
          json['min_year'] != null ? int.tryParse(json['min_year'].toString()) : null,
      maxYear:
          json['max_year'] != null ? int.tryParse(json['max_year'].toString()) : null,
      minGrade: json['min_grade'] != null
          ? int.tryParse(json['min_grade'].toString())
          : null,
      maxGrade: json['max_grade'] != null
          ? int.tryParse(json['max_grade'].toString())
          : null,
    );
  }
}
