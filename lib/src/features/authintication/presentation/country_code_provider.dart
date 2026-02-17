import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/helper/location/location_helper.dart';

final countryCodeProvider = StateNotifierProvider<CountryCodeNotifier, String>(
  (ref) => CountryCodeNotifier(),
);

class CountryCodeNotifier extends StateNotifier<String> {
  CountryCodeNotifier() : super('+966'); // Default to SA

  bool _isAutoDetected = false;

  Future<void> autoDetectCountry() async {
    if (_isAutoDetected) return; // Prevent repeated detection if already done

    final isoCode = await LocationHelper.getCurrentCountryCode();
    if (isoCode != null) {
      // Convert ISO code (e.g., 'EG') to dial code (e.g., '+20')
      // We can use CountryCode.fromCountryCode(isoCode).dialCode
      try {
        final country = CountryCode.fromCountryCode(isoCode);
        if (country.dialCode != null) {
          state = country.dialCode!;
          _isAutoDetected = true;
        }
      } catch (_) {
        // Fallback or ignore if lookup fails
      }
    }
  }

  void setCountryCode(String code) {
    state = code;
  }
}
