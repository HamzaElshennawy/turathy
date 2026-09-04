import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auction search field is editable (not readOnly)', () {
    final src = File(
      'lib/src/features/search/presentation/search_screen.dart',
    ).readAsStringSync();
    expect(src.contains('readOnly: true'), isFalse);
    expect(src.contains("Key('auction_search_field')"), isTrue);
  });

  test('sign-up and profile name fields use text keyboard not name', () {
    final signUp = File(
      'lib/src/features/authintication/presentation/sign_up_screen.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/src/features/authintication/presentation/complete_profile_screen.dart',
    ).readAsStringSync();
    expect(signUp.contains('TextInputType.name'), isFalse);
    expect(profile.contains('TextInputType.name'), isFalse);
    expect(signUp.contains('TextInputType.text'), isTrue);
    expect(profile.contains('TextInputType.text'), isTrue);
  });

  test('OTP tap re-shows keyboard instead of requestFocus only', () {
    final src = File(
      'lib/src/features/authintication/presentation/otp_screen.dart',
    ).readAsStringSync();
    expect(src.contains('showKeyboardFor(_otpFocusNode)'), isTrue);
    expect(src.contains("Key('otp_input_field')"), isTrue);
  });
}
