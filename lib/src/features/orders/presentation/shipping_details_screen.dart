import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/common_widgets/custom_card.dart';
import '../../../core/common_widgets/primary_button.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/constants/app_locations/app_locations.dart';
import '../../../utils/validators.dart';
import '../domain/order_model.dart';
import 'order_confirmation_screen.dart';

class ShippingDetailsScreen extends ConsumerStatefulWidget {
  final OrderModel initialOrder;

  const ShippingDetailsScreen({super.key, required this.initialOrder});

  @override
  ConsumerState<ShippingDetailsScreen> createState() =>
      _ShippingDetailsScreenState();
}

class _ShippingDetailsScreenState extends ConsumerState<ShippingDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  String? _selectedCountryCode;
  String? _selectedCityValue;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController();
    _addressController = TextEditingController();
    _selectedCountryCode = widget.initialOrder.cCountry;
    // Try to match city value case-insensitively against available cities of the selected country
    final GovernateOption governate = kGovernates.firstWhere(
      (g) => g.code.toLowerCase() == (_selectedCountryCode ?? '').toLowerCase(),
      orElse: () => kGovernates.first,
    );
    final String initialCity = widget.initialOrder.cCity;
    final CityOption matchedCity = governate.cities.firstWhere(
      (c) => c.value.toLowerCase() == initialCity.toLowerCase(),
      orElse: () => governate.cities.firstWhere(
        (c) => c.title.toLowerCase() == initialCity.toLowerCase(),
        orElse: () => governate.cities.isNotEmpty
            ? governate.cities.first
            : const CityOption(title: '', value: ''),
      ),
    );
    _selectedCityValue = (matchedCity.value.isNotEmpty)
        ? matchedCity.value
        : null;
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final local = _mobileController.text.trim();
      final e164 = '+966$local';
      final updatedOrder = widget.initialOrder.copyWith(
        cMobile: e164,
        cAddress: _addressController.text,
        cCity: _selectedCityValue ?? widget.initialOrder.cCity,
        cCountry: _selectedCountryCode ?? widget.initialOrder.cCountry,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(order: updatedOrder),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.shippingDetails.tr()),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildContactCard(theme),
                const SizedBox(height: 16),
                _buildAddressCard(theme),
                const SizedBox(height: 24),
                PrimaryButton(
                  onPressed: _submitForm,
                  text: AppStrings.continueToPayment.tr(),
                  isLoading: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(ThemeData theme) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.contactInformation.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: _buildTextField(
              controller: _mobileController,
              label: AppStrings.mobileNumber.tr(),
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: Validators.ksaLocalPhoneInputFormatters,
              validator: (value) {
                final error = Validators.ksaLocalPhoneValidator(value);
                if (error != null) return error;
                return null;
              },
              prefixText: '+966',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ThemeData theme) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.shippingAddress.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: AppStrings.address.tr(),
            icon: Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.addressRequired.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildCountryDropdown(theme),
          const SizedBox(height: 16),
          _buildCityDropdown(theme),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      validator: validator,
    );
  }

  Widget _buildCountryDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: kGovernates.any((g) => g.code == _selectedCountryCode)
          ? _selectedCountryCode
          : null,
      decoration: InputDecoration(
        labelText: AppStrings.country.tr(),
        prefixIcon: Icon(
          Icons.public,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: kGovernates
          .map(
            (g) =>
                DropdownMenuItem<String>(value: g.code, child: Text(g.title)),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountryCode = value;
          // Reset city when country changes
          _selectedCityValue = null;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppStrings.countryRequired.tr();
        }
        return null;
      },
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    final GovernateOption governate = kGovernates.firstWhere(
      (g) => g.code == _selectedCountryCode,
      orElse: () => kGovernates.first,
    );
    final List<CityOption> cities = (_selectedCountryCode == null)
        ? const []
        : governate.cities;
    final bool enabled = _selectedCountryCode != null && cities.isNotEmpty;

    // If previously selected city no longer exists under new country, clear it
    if (_selectedCityValue != null &&
        cities.indexWhere((c) => c.value == _selectedCityValue) == -1) {
      _selectedCityValue = null;
    }

    return DropdownButtonFormField<String>(
      value: _selectedCityValue,
      decoration: InputDecoration(
        labelText: AppStrings.city.tr(),
        prefixIcon: Icon(
          Icons.location_city,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: cities
          .map(
            (c) =>
                DropdownMenuItem<String>(value: c.value, child: Text(c.title)),
          )
          .toList(),
      onChanged: enabled
          ? (value) {
              setState(() {
                _selectedCityValue = value;
              });
            }
          : null,
      validator: (value) {
        if (!enabled) {
          return AppStrings.countryRequired.tr();
        }
        if (value == null || value.isEmpty) {
          return AppStrings.cityRequired.tr();
        }
        return null;
      },
    );
  }
}
