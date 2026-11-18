import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lot and share actions use the WhatsApp mark', () {
    final lot = File(
      'lib/src/features/auctions/presentation/auction_screen/widgets/lot_action_row.dart',
    ).readAsStringSync();
    final share = File(
      'lib/src/core/helper/share/item_share_sheet.dart',
    ).readAsStringSync();

    expect(lot.contains("asset: 'assets/icons/whats.png'"), isTrue);
    expect(lot.contains('Icons.chat'), isFalse);
    expect(share.contains("asset: 'assets/icons/whats.png'"), isTrue);
    expect(share.contains('Icons.chat'), isFalse);
  });
}
