import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_strings/app_strings.dart';

class Validators {
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

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.password.tr();
    }
    if (value.length < 4) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  // not empty validator
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  // E.164 international phone validator: requires leading + and 7-15 digits total after +
  static final RegExp _e164RegExp = RegExp(r'^\+[1-9]\d{6,14}$');

  static String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.phoneRequired.tr();
    }
    if (_e164RegExp.hasMatch(value) == false) {
      return AppStrings.phoneInvalidInternational.tr();
    }
    return null;
  }

  // Input formatters to allow only + and digits, and limit length to 16
  static final List<TextInputFormatter> phoneInputFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[+0-9]')),
    LengthLimitingTextInputFormatter(16),
  ];

  // KSA-specific: 9 digits local part, no leading zero (e.g., 5XXXXXXXX)
  static final RegExp _ksaLocalRegExp = RegExp(r'^[1-9]\d{8}$');

  static String? ksaLocalPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.phoneRequired.tr();
    }
    if (_ksaLocalRegExp.hasMatch(value) == false) {
      return AppStrings.phoneInvalidKsa.tr();
    }
    return null;
  }

  // Only digits, 9 max, and drop any leading zero the user tries to enter
  static final List<TextInputFormatter> ksaLocalPhoneInputFormatters =
      <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(9),
    _NoLeadingZeroFormatter(),
  ];
}

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
