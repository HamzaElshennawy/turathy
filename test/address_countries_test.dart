import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/constants/app_locations/app_locations.dart';

void main() {
  group('resolveAddressCountryIso', () {
    test('maps nationality ISO and English names', () {
      expect(resolveAddressCountryIso('JO'), 'JO');
      expect(resolveAddressCountryIso('Jordan'), 'JO');
      expect(resolveAddressCountryIso('IQ'), 'IQ');
    });

    test('maps Arabic titles via addressCountryTitleAr round-trip', () {
      expect(resolveAddressCountryIso(addressCountryTitleAr('JO')), 'JO');
      expect(resolveAddressCountryIso(addressCountryTitleAr('IQ')), 'IQ');
      expect(resolveAddressCountryIso(addressCountryTitleAr('SA')), 'SA');
    });

    test('maps legacy governate codes and titles', () {
      expect(resolveAddressCountryIso('KSA'), 'SA');
      expect(resolveAddressCountryIso('UAE'), 'AE');
      // Legacy UAE title in kGovernates (without hamza)
      expect(resolveAddressCountryIso('الامارات'), 'AE');
      expect(resolveAddressCountryIso('عمان'), 'OM');
    });

    test('returns null for empty/unknown', () {
      expect(resolveAddressCountryIso(null), isNull);
      expect(resolveAddressCountryIso(''), isNull);
      expect(resolveAddressCountryIso('Atlantis'), isNull);
    });
  });

  group('governateForAddressIso', () {
    test('GCC/Egypt keep city lists; Jordan has none', () {
      expect(governateForAddressIso('SA')?.code, 'KSA');
      expect(governateForAddressIso('AE')?.cities, isNotEmpty);
      expect(governateForAddressIso('JO'), isNull);
      expect(governateForAddressIso('IQ'), isNull);
    });
  });

  group('address country list', () {
    test('includes countries beyond the 7 governates', () {
      final codes = countries.map((c) => c.code).toSet();
      expect(codes.contains('JO'), isTrue);
      expect(codes.contains('IQ'), isTrue);
      expect(codes.contains('PS'), isTrue);
      expect(codes.length, greaterThanOrEqualTo(30));
      expect(kGovernates.length, 7);
    });

    test('saudi helpers and titles', () {
      expect(addressCountryTitleAr('JO'), isNotEmpty);
      expect(addressCountryTitleAr('SA'), isNotEmpty);
      expect(isSaudiAddressIso('SA'), isTrue);
      expect(isSaudiAddressIso('KSA'), isTrue);
      expect(isSaudiAddressIso('JO'), isFalse);
    });
  });
}
