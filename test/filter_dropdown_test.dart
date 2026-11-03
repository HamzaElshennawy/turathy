import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/search/domain/filter_options_model.dart';

void main() {
  test('dropdown stays on the hint until the value is a real option', () {
    expect(dropdownSelection(null, ['السعودية']), isNull);
    expect(dropdownSelection('', ['السعودية']), isNull);
    expect(dropdownSelection('all', ['السعودية']), isNull);
    expect(dropdownSelection('السعودية', ['السعودية', 'مصر']), 'السعودية');
  });
}
