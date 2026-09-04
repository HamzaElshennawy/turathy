import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/socket/socket_models.dart';

void main() {
  test('parseSocketDate accepts ISO, millis, and DateTime', () {
    final iso = parseSocketDate('2026-08-15T12:00:15.000Z');
    expect(iso, isNotNull);
    expect(parseSocketDate(null), isNull);
    expect(parseSocketDate(DateTime.utc(2026, 8, 15))?.year, 2026);
  });

  test('TimerExtendedEvent reads newExpiry alias', () {
    final event = TimerExtendedEvent.fromJson({
      'newExpiry': '2026-08-15T12:00:15.000Z',
      'seq': 3,
    });
    expect(event.expiryDate, isNotNull);
    expect(event.seq, 3);
  });

  test('BidPlacedEvent reads expiryDate for anti-snipe bump', () {
    final event = BidPlacedEvent.fromJson({
      'newBid': {'id': 1, 'user_id': 2, 'bid': 40, 'product_id': 9},
      'expiryDate': '2026-08-15T12:00:15.000Z',
    });
    expect(event.expiryDate, isNotNull);
  });
}
