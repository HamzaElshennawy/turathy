import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/products/presentation/product_screen.dart';

void main() {
  test('gallery arrows wrap at both ends', () {
    expect(galleryPageIndex(current: 0, count: 4, delta: 1), 1);
    expect(galleryPageIndex(current: 3, count: 4, delta: 1), 0);
    expect(galleryPageIndex(current: 0, count: 4, delta: -1), 3);
    expect(galleryPageIndex(current: 2, count: 4, delta: -1), 1);
  });
}
