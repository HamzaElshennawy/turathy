import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_strings/app_strings.dart';

/// {@category Utils}
///
/// Collection of input validation logic and formatting rules for the application's forms.
/// 
/// This class provides static methods used by [TextFormField] widgets for 
/// standardizing data entry. It includes support for email, password, and
/// specialized phone number formats (including KSA-specific logic).
class Validators {
  /// Validates an email address using a standard RFC 5322-compliant regex.
  /// 
  /// Returns a localized error message if the email is empty or invalid.
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.email.tr();
    }
    if (RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(value) ==
        false) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates a password's length and presence.
  /// 
  /// Currently enforces a minimum length of 8 characters (matching the logic in
  /// [passwordValidator]). Returns a localized error message if empty.
  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.password.tr();
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  /// Ensures a field is not null or empty.
  /// 
  /// Generic validator for any required text input.
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Regex for E.164 international phone number format.
  /// Requires leading '+' and 7-15 digits.
  static final RegExp _e164RegExp = RegExp(r'^\+[1-9]\d{6,14}$');

  /// Validates an international phone number (E.164).
  /// 
  /// Used for general account registration and contact verification.
  static String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.phoneRequired.tr();
    }
    if (_e164RegExp.hasMatch(value) == false) {
      return AppStrings.phoneInvalidInternational.tr();
    }
    return null;
  }

  /// A list of formatters for international phone input fields.
  /// 
  /// Allows only digits and the '+' prefix, with a 16-character limit.
  static final List<TextInputFormatter> phoneInputFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[+0-9]')),
    LengthLimitingTextInputFormatter(16),
  ];

  /// Regex for local Kingdom of Saudi Arabia (KSA) mobile format.
  /// Expects 9 digits starting with a non-zero digit (e.g., 5XXXXXXXX).
  static final RegExp _ksaLocalRegExp = RegExp(r'^[1-9]\d{8}$');

  /// Validates a local KSA mobile number.
  /// 
  /// Ensures the number follows the local dialing rules (9 digits, no leading 0).
  static String? ksaLocalPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.phoneRequired.tr();
    }
    if (_ksaLocalRegExp.hasMatch(value) == false) {
      return AppStrings.phoneInvalidKsa.tr();
    }
    return null;
  }

  /// A list of formatters for KSA-specific mobile input fields.
  /// 
  /// Restricts input to digits only, enforces a 9-digit max, and 
  /// automatically strips any leading zeros.
  static final List<TextInputFormatter> ksaLocalPhoneInputFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(9),
    _NoLeadingZeroFormatter(),
  ];
}

/// Helper formatter that automatically removes any leading '0' characters
/// while the user is typing.
class _NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    // Remove any leading zeros
    final sanitized = text.replaceFirst(RegExp(r'^0+'), '');
    if (sanitized == text) return newValue;
    final diff = text.length - sanitized.length;
    final selectionIndex =
        (newValue.selection.baseOffset - diff).clamp(0, sanitized.length);
    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
