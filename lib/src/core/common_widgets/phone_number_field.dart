/// {@category Components}
///
/// A specialized, locale-aware input field for international phone numbers.
/// 
/// This widget is specifically designed to handle the complexities of Middle Eastern 
/// and African phone numbering plans. It provides:
/// - **Filtered Country Picker**: Limited to Arab League nations as per project scope.
/// - **Smart Hinting**: Contextually updates the visual '9XXXXXXXX' placeholder based on the 
///   selected country prefix (e.g., SA vs. EG).
/// - **Automatic Normalization**: Uses [LeadingZeroFormatter] to strip trunk prefixes ('0') 
///   required for clean international dialing.
/// - **LTR Enforcement**: Wraps the input in a Left-to-Right [Directionality] even in 
///   RTL (Arabic) locales to ensure digits remain ordered correctly.
library;

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter/services.dart';

import 'white_rounded_text_form_field.dart';

/// An integrated phone number input consisting of a country prefix picker and a text field.
class PhoneNumberField extends StatelessWidget {
  /// The controller managing the digit-only portion of the phone number.
  final TextEditingController controller;

  /// Custom validation logic for the numeric string.
  final String? Function(String?)? validator;

  /// The currently active country dial code (e.g., '+966' or 'SA').
  final String initialCountryCode;

  /// Callback triggered when a user selects a different country from the dropdown.
  final void Function(CountryCode) onCountryChanged;

  /// The base placeholder text shown when the field is empty.
  final String hintText;

  /// Optional stylistic border configuration.
  final BorderSide? borderSide;

  /// If provided, overrides the default rounded style with a custom decoration.
  final InputDecoration? decoration;

  /// Creates a [PhoneNumberField] with pre-configured filters and formatters.
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.onCountryChanged,
    this.initialCountryCode = '+966',
    this.validator,
    this.hintText = '5XXXXXXXXX',
    this.borderSide,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    // Standardized picker for Arab countries
    final picker = CountryCodePicker(
      key: ValueKey(initialCountryCode),
      onChanged: onCountryChanged,
      initialSelection: initialCountryCode,
      favorite: const ['+966', 'SA'],
      // Restricted list based on the Turathy target market (Arab League)
      countryFilter: const [
        'SA', 'EG', 'AE', 'KW', 'QA', 'BH', 'OM', 'JO', 'LB', 'SY',
        'IQ', 'PS', 'YE', 'SD', 'LY', 'TN', 'DZ', 'MA', 'MR', 'SO',
        'DJ', 'KM',
      ],
      showCountryOnly: false,
      showOnlyCountryWhenClosed: false,
      alignLeft: false,
      padding: EdgeInsets.zero,
    );

    // Enforce canonical phone formats (digits only, no trunk zeros)
    final inputFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      LeadingZeroFormatter(),
    ];

    // Case 1: Custom Decorated TextFormField
    if (decoration != null) {
      return Directionality(
        textDirection: ui.TextDirection.ltr,
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: inputFormatters,
          decoration: decoration!.copyWith(
            prefixIcon: picker,
            hintText: _getHintForCountry(initialCountryCode),
          ),
          validator: validator,
        ),
      );
    }

    // Case 2: Standard Project Theme (Rounded White Field)
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: WhiteRoundedTextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        validator: validator,
        hintText: _getHintForCountry(initialCountryCode),
        inputFormatters: inputFormatters,
        borderSide: borderSide,
        prefixIcon: picker,
      ),
    );
  }

  /// Internal: Resolves a localized placeholder pattern for the provided dial [code].
  String _getHintForCountry(String code) {
    switch (code) {
      case '+966':
      case 'SA':
        return '5X XXX XXXX';
      case '+20':
      case 'EG':
        return '1X XXXX XXXX';
      case '+971':
      case 'AE':
        return '5X XXX XXXX';
      case '+965':
      case 'KW':
        return 'XXXX XXXX';
      case '+974':
      case 'QA':
        return 'XXXX XXXX';
      case '+973':
      case 'BH':
        return 'XXXX XXXX';
      case '+968':
      case 'OM':
        return 'XXXX XXXX';
      case '+962':
      case 'JO':
        return '7X XXXX XXXX';
      case '+961':
      case 'LB':
        return 'XX XXXXXX';
      case '+963':
      case 'SY':
        return '9X XXXXXXX';
      case '+964':
      case 'IQ':
        return '7X XXXX XXXX';
      case '+970':
      case 'PS':
        return '5X XXXXXXX';
      case '+967':
      case 'YE':
        return '7X XXXXXXX';
      case '+249':
      case 'SD':
        return '1X XXXXXXX';
      case '+218':
      case 'LY':
        return '9X XXXXXXX';
      case '+216':
      case 'TN':
        return 'XX XXX XXX';
      case '+213':
      case 'DZ':
        return '5X XXX XXXX';
      case '+212':
      case 'MA':
        return '6X XXX XXXX';
      case '+222':
      case 'MR':
        return 'XX XX XX XX';
      case '+252':
      case 'SO':
        return 'XX XXX XXX';
      case '+253':
      case 'DJ':
        return 'XX XX XX XX';
      case '+269':
      case 'KM':
        return '3X XX XX XX';
      default:
        return 'XXXXXXXXX';
    }
  }
}

/// A [TextInputFormatter] that prevents users from entering leading '0' characters.
/// 
/// Since country codes (e.g., +966) act as the primary prefix, redundant 
/// local trunk zeros (e.g., 055...) are stripped to ensure the backend 
/// receives a canonical international number.
class LeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith('0')) {
      final stripped = newValue.text.replaceFirst(RegExp(r'^0+'), '');

      // Recalculate cursor offset to prevent jumping
      int offset =
          newValue.selection.baseOffset -
          (newValue.text.length - stripped.length);
      if (offset < 0) offset = 0;

      return TextEditingValue(
        text: stripped,
        selection: TextSelection.collapsed(offset: offset),
      );
    }
    return newValue;
  }
}

