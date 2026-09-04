import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/fcm/notification_prefs.dart';

void main() {
  test('resolveType prefers data.type', () {
    expect(
      NotificationPrefs.resolveType({'type': 'OUTBID', 'notificationType': 'X'}),
      'OUTBID',
    );
    expect(
      NotificationPrefs.resolveType({'notificationType': 'AUCTION_STARTED'}),
      'AUCTION_STARTED',
    );
    expect(NotificationPrefs.resolveType({}), isNull);
  });
}
