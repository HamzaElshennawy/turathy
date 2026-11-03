import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/home/domain/category_model.dart';
import 'package:turathy/src/features/home/presentation/category_hub/category_auction_tile.dart';
import 'package:turathy/src/features/products/domain/product_model.dart';

ProductModel _product(String title) {
  return ProductModel(
    id: 1,
    title: title,
    titleAr: title,
    name: title,
    description: 'desc',
    price: 40,
    imageUrl: 'https://example.com/a.jpg',
    category: 'Banknote',
    brand: 'turathy',
    stock: 1,
    discount: 0.0,
    rating: 0.0,
    reviews: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  test('store category matches Arabic or English catalog name', () {
    final paper = CategoryModel(
      id: 8,
      nameAr: 'عملات الورقية',
      nameEn: 'Banknote',
    );

    expect(productCategoryMatches('Banknote', paper), isTrue);
    expect(productCategoryMatches(' banknote ', paper), isTrue);
    expect(productCategoryMatches('عملات الورقية', paper), isTrue);
    expect(productCategoryMatches('Accessories', paper), isFalse);
    expect(productCategoryMatches(null, paper), isFalse);
  });

  test('product headline breaks at the first dash', () {
    const title = 'بوكس حفظ رولات العملات المعدنية - 10 رولات بلاستيكية';
    final headline = _product(title).localizedHeadline('ar');

    expect(headline, 'بوكس حفظ رولات العملات المعدنية\n10 رولات بلاستيكية');
  });

  test('auction cover prefers the main photo then the gallery', () {
    expect(
      resolveAuctionCoverUrl(imageUrl: 'https://cdn.example/cover.jpg'),
      'https://cdn.example/cover.jpg',
    );
    expect(
      resolveAuctionCoverUrl(
        imageUrl: '  ',
        gallery: ['', 'https://cdn.example/gallery.jpg'],
      ),
      'https://cdn.example/gallery.jpg',
    );
    expect(resolveAuctionCoverUrl(imageUrl: null), isEmpty);
  });

  test('countdown keeps hours for a multi-day wait', () {
    expect(
      formatAuctionCountdown(
        const Duration(hours: 105, minutes: 22, seconds: 23),
      ),
      '105:22:23',
    );
    expect(
      formatAuctionCountdown(const Duration(minutes: 4, seconds: 5)),
      '04:05',
    );
  });
}
