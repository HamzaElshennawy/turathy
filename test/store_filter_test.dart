import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/home/domain/category_model.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';
import 'package:turathy/src/features/search/domain/filter_state.dart';

ProductModel _product({
  required String title,
  String? category,
  double price = 30,
  String? country,
  int? date,
  String? gradingCompany,
}) {
  final now = DateTime.utc(2026);
  return ProductModel(
    id: 1,
    title: title,
    name: title,
    description: '',
    price: price,
    imageUrl: '',
    category: category,
    brand: '',
    stock: 1,
    discount: 0,
    rating: 0,
    reviews: 0,
    country: country,
    date: date,
    gradingCompany: gradingCompany,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('store filter matches category and search without a new download', () {
    final category = CategoryModel()
      ..id = 4
      ..nameAr = 'عملات';
    final match = _product(title: 'ورقة يمنية', category: 'عملات');
    final other = _product(title: 'خنجر', category: 'أسلحة');

    expect(
      productMatchesStoreFilters(match, FilterState(selectedCategoryID: 4, searchText: 'يمنية'), category),
      isTrue,
    );
    expect(
      productMatchesStoreFilters(other, FilterState(selectedCategoryID: 4), category),
      isFalse,
    );
    expect(
      productMatchesStoreFilters(match, FilterState(minPrice: 100), null),
      isFalse,
    );
    final saudi = _product(title: 'ريال', category: 'عملات', country: 'السعودية', date: 1952, gradingCompany: 'PMG');
    expect(productMatchesStoreFilters(saudi, FilterState(country: 'السعودية', dateFrom: 1950, dateTo: 1960, gradingCompany: 'PMG'), null), isTrue);
    expect(productMatchesStoreFilters(saudi, FilterState(country: 'مصر'), null), isFalse);
  });
}
