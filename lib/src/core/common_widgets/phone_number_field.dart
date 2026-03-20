import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter/services.dart';

import 'white_rounded_text_form_field.dart';

class PhoneNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String initialCountryCode;
  final void Function(CountryCode) onCountryChanged;

  // Use this for Auth screens (which use WhiteRoundedTextFormField)
  final String hintText;
  final BorderSide? borderSide;

  // Use this for screens that need custom decoration (like AddEditAddressScreen)
  final InputDecoration? decoration;

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
    final picker = CountryCodePicker(
      key: ValueKey(initialCountryCode),
      onChanged: onCountryChanged,
      initialSelection: initialCountryCode,
      favorite: const ['+966', 'SA'],
      countryFilter: const [
        'SA',
        'EG',
        'AE',
        'KW',
        'QA',
        'BH',
        'OM',
        'JO',
        'LB',
        'SY',
        'IQ',
        'PS',
        'YE',
        'SD',
        'LY',
        'TN',
        'DZ',
        'MA',
        'MR',
        'SO',
        'DJ',
        'KM',
      ],
      showCountryOnly: false,
      showOnlyCountryWhenClosed: false,
      alignLeft: false,
      padding: EdgeInsets.zero,
    );

    final inputFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      LeadingZeroFormatter(),
    ];

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

class LeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith('0')) {
      final stripped = newValue.text.replaceFirst(RegExp(r'^0+'), '');

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
