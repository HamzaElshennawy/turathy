import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/live_activity/android_ongoing_gateway.dart';

void main() {
  test('ongoing notice uses the lot number, Arabic status, and public price', () {
    final notice = androidLiveNotice(
      lotNumber: '18',
      status: 'Bidding',
      price: '250',
    );

    expect(notice.title, 'بند 18');
    expect(notice.body, 'جاري المزايدة · 250 ر.س');
  });

  test('ending notice omits an empty price', () {
    final notice = androidLiveNotice(
      lotNumber: '',
      status: 'Ending',
      price: '',
    );

    expect(notice.title, 'مزاد مباشر');
    expect(notice.body, 'ينتهي قريباً');
  });
}
