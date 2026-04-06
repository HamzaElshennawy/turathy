/// {@category Presentation}
///
/// Provider and notifier for managing the selected country dial code.
/// 
/// This is used throughout authentication forms (Sign In, Sign Up) to ensure
/// phone numbers are prefixed with the correct international dial code.
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/helper/location/location_helper.dart';

/// Global provider for the current country dial code (e.g., '+966').
final countryCodeProvider = StateNotifierProvider<CountryCodeNotifier, String>(
  (ref) => CountryCodeNotifier(),
);

/// Manages the state of the selected country dial code.
/// 
/// Supports manual updates and automatic detection based on device location.
class CountryCodeNotifier extends StateNotifier<String> {
  /// Initializes with Saudi Arabia (+966) as the default.
  CountryCodeNotifier() : super('+966');

  bool _isAutoDetected = false;

  /// Attempts to detect the user's current country using [LocationHelper].
  /// 
  /// If successful, converts the ISO code (e.g., 'EG') to a dial code (e.g., '+20')
  /// and updates the state. Detection is only performed once to avoid 
  /// overriding manual user selections.
  Future<void> autoDetectCountry() async {
    if (_isAutoDetected) return;

    final isoCode = await LocationHelper.getCurrentCountryCode();
    if (isoCode != null) {
      try {
        final country = CountryCode.fromCountryCode(isoCode);
        if (country.dialCode != null) {
          state = country.dialCode!;
          _isAutoDetected = true;
        }
      } catch (_) {
        // Silent fail: keep existing/default code.
      }
    }
  }

  /// Manually updates the dial code.
  void setCountryCode(String code) {
    state = code;
  }
}

