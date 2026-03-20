import 'package:flutter/material.dart';

/// Saudi National Address (Wasl) Short Address Decoder
/// Format: RRDD#### where RR = region, DD = district code, #### = building number
/// Example: RAGI2929

class SaudiAddressDecoder {
  // Region codes (first 2 letters of short address)
  static const Map<String, String> _regionCodes = {
    'RA': 'Riyadh',
    'MK': 'Makkah',
    'MD': 'Madinah',
    'EP': 'Eastern Province',
    'AS': 'Asir',
    'TB': 'Tabuk',
    'QS': 'Qassim',
    'HA': 'Hail',
    'NJ': 'Najran',
    'JZ': 'Jazan',
    'NB': 'Northern Borders',
    'JF': 'Al-Jawf',
    'BH': 'Al-Bahah',
  };

  /// Validates whether a string matches the short address format (4 letters + 4 digits)
  static bool isValid(String shortAddress) {
    final regex = RegExp(r'^[A-Za-z]{4}\d{4}$');
    return regex.hasMatch(shortAddress.trim());
  }

  /// Decodes a short address into its components
  /// Returns null if the format is invalid
  static SaudiAddress? decode(String shortAddress) {
    final cleaned = shortAddress.trim().toUpperCase();

    if (!isValid(cleaned)) return null;

    final regionCode = cleaned.substring(0, 2);
    final districtCode = cleaned.substring(2, 4);
    final buildingNumber = cleaned.substring(4);
    final regionName = _regionCodes[regionCode];

    debugPrint('raw: $cleaned');
    debugPrint('regionCode: $regionCode');
    debugPrint('districtCode: $districtCode');
    debugPrint('buildingNumber: $buildingNumber');
    debugPrint('regionName: $regionName');

    return SaudiAddress(
      raw: cleaned,
      regionCode: regionCode,
      regionName: regionName,
      districtCode: districtCode,
      buildingNumber: buildingNumber,
    );
  }
}

class SaudiAddress {
  /// The original short address string e.g. RAGI2929
  final String raw;

  /// 2-letter region code e.g. "RA"
  final String regionCode;

  /// Human-readable region name e.g. "Riyadh" (null if code is unrecognized)
  final String? regionName;

  /// 2-letter district code e.g. "GI" (requires API to resolve to name)
  final String districtCode;

  /// 4-digit building number e.g. "2929"
  final String buildingNumber;

  const SaudiAddress({
    required this.raw,
    required this.regionCode,
    required this.regionName,
    required this.districtCode,
    required this.buildingNumber,
  });

  /// Whether the region was successfully resolved to a name
  bool get isRegionResolved => regionName != null;

  /// Returns a readable summary of what was decoded
  String get summary {
    final region = regionName ?? 'Unknown Region ($regionCode)';
    return '$region — District Code: $districtCode — Building: $buildingNumber';
  }

  @override
  String toString() => summary;

  Map<String, dynamic> toMap() => {
    'raw': raw,
    'regionCode': regionCode,
    'regionName': regionName,
    'districtCode': districtCode,
    'buildingNumber': buildingNumber,
  };
}
