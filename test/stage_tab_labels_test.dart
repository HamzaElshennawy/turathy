import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> loadLang(String code) {
    final file = File('assets/lang/$code.json');
    expect(file.existsSync(), isTrue, reason: 'missing assets/lang/$code.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('customer stage tab labels AR/EN match approved copy', () {
    final ar = loadLang('ar');
    final en = loadLang('en');

    expect(ar['tabAllItems'], 'بنود المزاد');
    expect(ar['tabMyBids'], 'مزايداتي');
    expect(ar['tabWinning'], 'أعلى مزايدة');
    expect(ar['tabLosing'], 'تمت المزايدة عليك');

    expect(en['tabAllItems'], 'Auction Lots');
    expect(en['tabMyBids'], 'My Bids');
    expect(en['tabWinning'], 'Highest Bid');
    expect(en['tabLosing'], 'Outbid');
  });

  test('unsold lot-end copy is present', () {
    final ar = loadLang('ar');
    final en = loadLang('en');
    expect(ar['unsold'], 'لم تُبع');
    expect(en['unsold'], 'Unsold');
  });
}
