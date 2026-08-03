import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/constants/app_locations/app_locations.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/common_widgets/phone_number_field.dart';
import '../../../utils/saudi_address_decoder.dart';
import '../data/address_repository.dart';
import '../domain/user_address_model.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final UserAddressModel? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _shortAddressController;
  /// Nationality ISO (e.g. SA, JO) — not legacy KSA/UAE codes.
  String? _selectedCountryCode;
  String? _selectedCityValue;
  String _mobileCountryCode = '+966';
  bool _isDefault = false;
  bool _isSaving = false;
  String? _errorMessage;
  SaudiAddress? _decodedAddress;

  bool get _isEditing => widget.address != null;
  bool get _isSaudiArabia => isSaudiAddressIso(_selectedCountryCode);

  GovernateOption? get _selectedGovernate =>
      governateForAddressIso(_selectedCountryCode);

  bool get _hasCityList =>
      _selectedGovernate != null && _selectedGovernate!.cities.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _labelController = TextEditingController(text: addr?.label ?? '');
    _nameController = TextEditingController(
      text: addr?.name ?? CachedVariables.userName ?? '',
    );

    // Strip country code from mobile to avoid duplication with the picker
    String initialMobile = addr?.mobile ?? CachedVariables.phone_number ?? '';
    if (initialMobile.startsWith('+')) {
      // Known dial codes (longest first) to avoid greedy matching issues
      const knownCodes = [
        '+966', '+971', '+965', '+974', '+973', '+968', '+962', '+961', '+963',
        '+964', '+970', '+967', '+249', '+218', '+216', '+213', '+212', '+222',
        '+252', '+253', '+269', '+20', '+1', '+44', '+33', '+49', '+90', '+91',
        '+92', '+880', '+63', '+62', '+60', '+86',
      ];
      bool matched = false;
      for (final code in knownCodes) {
        if (initialMobile.startsWith(code)) {
          _mobileCountryCode = code;
          initialMobile = initialMobile.substring(code.length);
          matched = true;
          break;
        }
      }
      if (!matched) {
        final match = RegExp(r'^\+(\d{1,3})').firstMatch(initialMobile);
        if (match != null) {
          _mobileCountryCode = '+${match.group(1)!}';
          initialMobile = initialMobile.substring(match.group(0)!.length);
        }
      }
    }
    _mobileController = TextEditingController(text: initialMobile);

    _addressController = TextEditingController(text: addr?.address ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _shortAddressController = TextEditingController(
      text: addr?.shortAddress ?? '',
    );

    _isDefault = addr?.isDefault ?? false;

    if (addr != null) {
      _selectedCountryCode = resolveAddressCountryIso(addr.country);
      final gov = governateForAddressIso(_selectedCountryCode);
      if (gov != null && addr.city != null && addr.city!.isNotEmpty) {
        final city = gov.cities
            .where((c) => c.title == addr.city || c.value == addr.city)
            .firstOrNull;
        _selectedCityValue = city?.value;
        if (city == null) {
          // Keep free-text city for unmatched stored values
          _cityController.text = addr.city!;
        }
      }

      if (addr.shortAddress != null && addr.shortAddress!.isNotEmpty) {
        _decodedAddress = SaudiAddressDecoder.decode(addr.shortAddress!);
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _shortAddressController.dispose();
    super.dispose();
  }

  void _onShortAddressChanged(String value) {
    final cleaned = value.trim().toUpperCase();
    if (cleaned.length == 8) {
      final decoded = SaudiAddressDecoder.decode(cleaned);
      setState(() => _decodedAddress = decoded);
    } else {
      if (_decodedAddress != null) {
        setState(() => _decodedAddress = null);
      }
    }
  }

  String _fullMobile() {
    final local = _mobileController.text.trim();
    if (local.isEmpty) return local;
    if (local.startsWith('+')) return local;
    final dial = _mobileCountryCode.startsWith('+')
        ? _mobileCountryCode
        : '+$_mobileCountryCode';
    return '$dial$local';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountryCode == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final userId = CachedVariables.userId!;
      final countryTitle = addressCountryTitleAr(_selectedCountryCode!);

      String cityTitle;
      if (_isSaudiArabia && _decodedAddress != null) {
        final regionName =
            _decodedAddress!.regionName ?? _decodedAddress!.regionCode;
        final ksaCities = kGovernates.firstWhere((g) => g.code == 'KSA').cities;
        final matchedCity = ksaCities
            .where(
              (c) =>
                  c.value.toLowerCase() == regionName.toLowerCase() ||
                  c.title == regionName,
            )
            .firstOrNull;
        cityTitle = matchedCity?.title ?? regionName;
      } else if (_hasCityList && _selectedCityValue != null) {
        cityTitle = _selectedGovernate!.cities
            .firstWhere((c) => c.value == _selectedCityValue)
            .title;
      } else {
        cityTitle = _cityController.text.trim();
      }

      final payload = <String, dynamic>{
        'label': _labelController.text.trim().isNotEmpty
            ? _labelController.text.trim()
            : null,
        'name': _nameController.text.trim(),
        'mobile': _fullMobile(),
        'country': countryTitle,
        'city': cityTitle,
        'address': _isSaudiArabia && _decodedAddress != null
            ? _decodedAddress!.districtCode
            : _addressController.text.trim(),
        'isDefault': _isDefault,
      };

      if (_isSaudiArabia && _shortAddressController.text.trim().isNotEmpty) {
        payload['shortAddress'] = _shortAddressController.text
            .trim()
            .toUpperCase();
      }

      UserAddressModel result;

      if (_isEditing) {
        payload['address_id'] = widget.address!.id;
        result = await ref
            .read(addressRepositoryProvider)
            .updateAddress(payload);
      } else {
        payload['user_id'] = userId;
        result = await ref.read(addressRepositoryProvider).addAddress(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.addressSavedSuccessfully.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? AppStrings.editAddress.tr()
              : AppStrings.addNewAddress.tr(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _labelController,
                label: AppStrings.addressLabel.tr(),
                icon: Icons.label_outline,
                required: false,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _nameController,
                label: AppStrings.recipientName.tr(),
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              PhoneNumberField(
                controller: _mobileController,
                initialCountryCode: _mobileCountryCode,
                onCountryChanged: (country) {
                  if (country.dialCode != null) {
                    setState(() {
                      _mobileCountryCode = country.dialCode!;
                    });
                  }
                },
                decoration: _inputDecoration(
                  AppStrings.recipientMobile.tr(),
                  Icons.phone_outlined,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return AppStrings.mobileNumberRequired.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildCountryDropdown(theme),
              const SizedBox(height: 16),

              if (_isSaudiArabia) ...[
                _buildShortAddressField(theme),
                const SizedBox(height: 16),
                if (_decodedAddress != null) _buildDecodedCityField(theme),
                if (_decodedAddress != null) const SizedBox(height: 16),
                if (_decodedAddress != null)
                  _buildReadOnlyField(
                    theme,
                    label: AppStrings.district.tr(),
                    value: _decodedAddress!.districtCode,
                    icon: Icons.map_outlined,
                    key: 'district_${_decodedAddress!.districtCode}',
                  ),
                if (_decodedAddress != null) const SizedBox(height: 16),
                if (_decodedAddress != null)
                  _buildReadOnlyField(
                    theme,
                    label: AppStrings.buildingNO.tr(),
                    value: _decodedAddress!.buildingNumber,
                    icon: Icons.apartment_outlined,
                    key: 'building_${_decodedAddress!.buildingNumber}',
                  ),
                if (_decodedAddress != null) const SizedBox(height: 16),
              ],

              if (!_isSaudiArabia) ...[
                if (_hasCityList)
                  _buildCityDropdown(theme)
                else
                  TextFormField(
                    controller: _cityController,
                    decoration: _inputDecoration(
                      AppStrings.city.tr(),
                      Icons.location_city,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? AppStrings.cityRequired.tr()
                        : null,
                  ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: AppStrings.address.tr(),
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],

              SwitchListTile(
                title: Text(AppStrings.setAsDefault.tr()),
                subtitle: Text(
                  AppStrings.defaultAddress.tr(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? AppStrings.editAddress.tr()
                            : AppStrings.addNewAddress.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon),
      validator: required
          ? (v) => (v == null || v.isEmpty)
                ? AppStrings.addressRequired.tr()
                : null
          : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildCountryDropdown(ThemeData theme) {
    final isAr = context.locale.languageCode == 'ar';
    // Ensure value exists in items (legacy/unknown → null)
    final codes = countries.map((c) => c.code).toSet();
    final value =
        _selectedCountryCode != null && codes.contains(_selectedCountryCode)
            ? _selectedCountryCode
            : null;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(AppStrings.country.tr(), Icons.public),
      items: countries
          .map(
            (c) => DropdownMenuItem(
              value: c.code,
              child: Text(isAr ? c.nameAr : c.nameEn),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() {
        _selectedCountryCode = v;
        _selectedCityValue = null;
        _cityController.clear();
        if (!isSaudiAddressIso(v)) {
          _shortAddressController.clear();
          _decodedAddress = null;
        }
      }),
      validator: (v) => v == null ? AppStrings.countryRequired.tr() : null,
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    final gov = _selectedGovernate;
    final cities = gov?.cities ?? [];

    if (_selectedCityValue != null &&
        cities.indexWhere((c) => c.value == _selectedCityValue) == -1) {
      _selectedCityValue = null;
    }

    return DropdownButtonFormField<String>(
      value: _selectedCityValue,
      decoration: _inputDecoration(AppStrings.city.tr(), Icons.location_city),
      items: cities
          .map((c) => DropdownMenuItem(value: c.value, child: Text(c.title)))
          .toList(),
      onChanged: _selectedCountryCode != null
          ? (v) => setState(() => _selectedCityValue = v)
          : null,
      validator: (v) => v == null ? AppStrings.cityRequired.tr() : null,
    );
  }

  Widget _buildShortAddressField(ThemeData theme) {
    return TextFormField(
      controller: _shortAddressController,
      textDirection: ui.TextDirection.ltr,
      textCapitalization: TextCapitalization.characters,
      maxLength: 8,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        UpperCaseTextFormatter(),
      ],
      decoration: _inputDecoration(
        AppStrings.shortAddressCode.tr(),
        Icons.pin_drop_outlined,
      ).copyWith(hintText: AppStrings.shortAddressHint.tr(), counterText: ''),
      onChanged: _onShortAddressChanged,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return AppStrings.addressRequired.tr();
        }
        if (!SaudiAddressDecoder.isValid(v.trim())) {
          return AppStrings.invalidShortAddress.tr();
        }
        return null;
      },
    );
  }

  Widget _buildReadOnlyField(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required String key,
  }) {
    return TextFormField(
      key: ValueKey(key),
      initialValue: value,
      readOnly: true,
      enabled: false,
      decoration: _inputDecoration(label, icon).copyWith(
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDecodedCityField(ThemeData theme) {
    final regionName =
        _decodedAddress?.regionName ?? _decodedAddress?.regionCode ?? '';
    final ksaCities =
        kGovernates.where((g) => g.code == 'KSA').firstOrNull?.cities ?? [];
    final matchedCity = ksaCities
        .where(
          (c) =>
              c.value.toLowerCase() == regionName.toLowerCase() ||
              c.title == regionName,
        )
        .firstOrNull;
    final displayValue = matchedCity?.title ?? regionName;

    return TextFormField(
      key: ValueKey('city_$displayValue'),
      initialValue: displayValue,
      readOnly: true,
      enabled: false,
      decoration:
          _inputDecoration(
            AppStrings.cityArea.tr(),
            Icons.location_city,
          ).copyWith(
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.5,
            ),
          ),
    );
  }
}

/// Formatter that converts input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
