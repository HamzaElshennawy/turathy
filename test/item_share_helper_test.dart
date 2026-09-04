import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/share/item_share_helper.dart';

void main() {
  test('auctionLotUrl includes auction id and optional lot/product', () {
    expect(
      ItemShareHelper.auctionLotUrl(auctionId: 12),
      'https://alturathaljmeel.com.sa/auctions/12',
    );
    expect(
      ItemShareHelper.auctionLotUrl(auctionId: 12, lotNumber: 5, productId: 99),
      'https://alturathaljmeel.com.sa/auctions/12?lot=5&product=99',
    );
  });

  test('productUrl is stable', () {
    expect(
      ItemShareHelper.productUrl(productId: 7),
      'https://alturathaljmeel.com.sa/products/7',
    );
  });

  test('whatsappAppUri uses app scheme and never wa.me browser URL', () {
    final uri = ItemShareHelper.whatsappAppUri('Title\nhttps://example.com/p/1');
    expect(uri.scheme, 'whatsapp');
    expect(uri.toString().startsWith('whatsapp://send?text='), isTrue);
    expect(uri.toString().contains('wa.me'), isFalse);
    expect(uri.toString().contains('https://'), isFalse);
  });

  test('smsAppUri opens native SMS composer', () {
    final uri = ItemShareHelper.smsAppUri('Hello lot');
    expect(uri.scheme, 'sms');
    expect(uri.queryParameters['body'], 'Hello lot');
  });

  test('shareMessage joins title and url', () {
    expect(
      ItemShareHelper.shareMessage(title: 'Lot A', url: 'https://x/y'),
      'Lot A\nhttps://x/y',
    );
  });
}
