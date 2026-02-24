import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/constants/app_locations/app_locations.dart';
import '../../../core/helper/cache/cached_variables.dart';
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
  String? _selectedCountryCode;
  String? _selectedCityValue;
  bool _isDefault = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.address != null;

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
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
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
      final cityTitle = kGovernates
          .firstWhere((g) => g.code == _selectedCountryCode)
          .cities
          .firstWhere((c) => c.value == _selectedCityValue)
          .title;

      UserAddressModel result;

      if (_isEditing) {
        result = await ref.read(addressRepositoryProvider).updateAddress({
          'address_id': widget.address!.id,
          'label': _labelController.text.trim().isNotEmpty
              ? _labelController.text.trim()
              : null,
          'name': _nameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'country': countryTitle,
          'city': cityTitle,
          'address': _addressController.text.trim(),
          'isDefault': _isDefault,
        });
      } else {
        result = await ref.read(addressRepositoryProvider).addAddress({
          'user_id': userId,
          'label': _labelController.text.trim().isNotEmpty
              ? _labelController.text.trim()
              : null,
          'name': _nameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'country': countryTitle,
          'city': cityTitle,
          'address': _addressController.text.trim(),
          'isDefault': _isDefault,
        });
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

              // City
              _buildCityDropdown(theme),
              const SizedBox(height: 16),

              // Address
              _buildTextField(
                controller: _addressController,
                label: AppStrings.address.tr(),
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

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
      }),
      validator: (v) => v == null ? AppStrings.countryRequired.tr() : null,
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    final gov = kGovernates
        .where((g) => g.code == _selectedCountryCode)
        .firstOrNull;
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
}
