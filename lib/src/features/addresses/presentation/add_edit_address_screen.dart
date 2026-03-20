import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/constants/app_locations/app_locations.dart';
import '../../../core/helper/cache/cached_variables.dart';
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
  late TextEditingController _shortAddressController;
  String? _selectedCountryCode;
  String? _selectedCityValue;
  bool _isDefault = false;
  bool _isSaving = false;
  String? _errorMessage;
  SaudiAddress? _decodedAddress;

  bool get _isEditing => widget.address != null;
  bool get _isSaudiArabia => _selectedCountryCode == 'KSA';

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _labelController = TextEditingController(text: addr?.label ?? '');
    _nameController = TextEditingController(
      text: addr?.name ?? CachedVariables.userName ?? '',
    );
    _mobileController = TextEditingController(
      text: addr?.mobile ?? CachedVariables.phone_number ?? '',
    );
    _addressController = TextEditingController(text: addr?.address ?? '');
    _shortAddressController = TextEditingController(
      text: addr?.shortAddress ?? '',
    );

    _isDefault = addr?.isDefault ?? false;

    if (addr != null) {
      // Match country
      final gov = kGovernates
          .where((g) => g.title == addr.country || g.code == addr.country)
          .firstOrNull;
      if (gov != null) {
        _selectedCountryCode = gov.code;
        // Match city
        final city = gov.cities
            .where((c) => c.title == addr.city || c.value == addr.city)
            .firstOrNull;
        _selectedCityValue = city?.value;
      }

      // Decode short address if available
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final userId = CachedVariables.userId!;
      final countryTitle = kGovernates
          .firstWhere((g) => g.code == _selectedCountryCode)
          .title;

      String cityTitle;
      if (_isSaudiArabia && _decodedAddress != null) {
        // Match the decoded region name against the KSA city list
        final regionName =
            _decodedAddress!.regionName ?? _decodedAddress!.regionCode;
        final ksaCities = kGovernates.firstWhere((g) => g.code == 'KSA').cities;
        // Try matching by value first (e.g., 'Riyadh'), then by title
        final matchedCity = ksaCities
            .where(
              (c) =>
                  c.value.toLowerCase() == regionName.toLowerCase() ||
                  c.title == regionName,
            )
            .firstOrNull;
        cityTitle = matchedCity?.title ?? regionName;
      } else {
        cityTitle = kGovernates
            .firstWhere((g) => g.code == _selectedCountryCode)
            .cities
            .firstWhere((c) => c.value == _selectedCityValue)
            .title;
      }

      final payload = <String, dynamic>{
        'label': _labelController.text.trim().isNotEmpty
            ? _labelController.text.trim()
            : null,
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'country': countryTitle,
        'city': cityTitle,
        'address': _isSaudiArabia && _decodedAddress != null
            ? _decodedAddress!.districtCode
            : _addressController.text.trim(),
        'isDefault': _isDefault,
      };

      // Include short address for Saudi Arabia
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
              // Label (optional)
              _buildTextField(
                controller: _labelController,
                label: AppStrings.addressLabel.tr(),
                icon: Icons.label_outline,
                required: false,
              ),
              const SizedBox(height: 16),

              // Recipient name
              _buildTextField(
                controller: _nameController,
                label: AppStrings.recipientName.tr(),
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Mobile
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration:
                      _inputDecoration(
                        AppStrings.recipientMobile.tr(),
                        Icons.phone_outlined,
                      ).copyWith(
                        prefixIcon: CountryCodePicker(
                          onChanged: (country) {},
                          initialSelection: '+966',
                          favorite: const ['+966', 'SA'],
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                          padding: EdgeInsets.zero,
                        ),
                        hintText: '5XXXXXXXXX',
                      ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.mobileNumberRequired.tr();
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Country
              _buildCountryDropdown(theme),
              const SizedBox(height: 16),

              // Saudi Short Address Code (only when KSA is selected)
              if (_isSaudiArabia) ...[
                _buildShortAddressField(theme),
                const SizedBox(height: 16),

                // Decoded city/region (non-editable)
                if (_decodedAddress != null) _buildDecodedCityField(theme),
                if (_decodedAddress != null) const SizedBox(height: 16),

                // District code (non-editable, 3rd+4th letters)
                if (_decodedAddress != null)
                  _buildReadOnlyField(
                    theme,
                    label: AppStrings.district.tr(),
                    value: _decodedAddress!.districtCode,
                    icon: Icons.map_outlined,
                    key: 'district_${_decodedAddress!.districtCode}',
                  ),
                if (_decodedAddress != null) const SizedBox(height: 16),

                // Building number (non-editable, last 4 digits)
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

              // City dropdown (only for non-KSA countries)
              if (!_isSaudiArabia) ...[
                _buildCityDropdown(theme),
                const SizedBox(height: 16),
              ],

              // Address (only for non-KSA countries)
              if (!_isSaudiArabia) ...[
                _buildTextField(
                  controller: _addressController,
                  label: AppStrings.address.tr(),
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],

              // Default toggle
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
    return DropdownButtonFormField<String>(
      value: _selectedCountryCode,
      decoration: _inputDecoration(AppStrings.country.tr(), Icons.public),
      items: kGovernates
          .map((g) => DropdownMenuItem(value: g.code, child: Text(g.title)))
          .toList(),
      onChanged: (v) => setState(() {
        _selectedCountryCode = v;
        _selectedCityValue = null;
        // Reset short address if switching away from KSA
        if (v != 'KSA') {
          _shortAddressController.clear();
          _decodedAddress = null;
        }
      }),
      validator: (v) => v == null ? AppStrings.countryRequired.tr() : null,
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    final gov = kGovernates
        .where((g) => g.code == _selectedCountryCode)
        .firstOrNull;

    debugPrint('gov: ${gov?.title}');
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

  /// Short address code input field for Saudi Arabia
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

  /// Generic non-editable text field for decoded short address components
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

  /// Non-editable display of the decoded city/region from the short address
  Widget _buildDecodedCityField(ThemeData theme) {
    // Look up the Arabic title from the KSA city list for display consistency
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
