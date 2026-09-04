import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/common_widgets/phone_number_field.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

void main() {
  test('login phone field lists all countries, not a regional filter', () {
    expect(PhoneNumberField.showAllCountries, isTrue);
  });

  test('country picker chrome uses app-language keys, not package English defaults', () {
    expect(AppStrings.selectCountry, 'selectCountry');
    expect(AppStrings.searchCountry, 'searchCountry');
    expect(AppStrings.noCountryFound, 'noCountryFound');
  });
}
