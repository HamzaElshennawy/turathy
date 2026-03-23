import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_locations/app_locations.dart';
import 'package:turathy/src/features/main_screen.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/common_widgets/phone_number_field.dart';
import '../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/socket/socket_models.dart';
import '../../addresses/presentation/add_edit_address_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/address_model.dart';
import 'auth_controller.dart';
import 'country_code_provider.dart';

/// Country list with 2-letter ISO codes for the nationality picker.

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  String? _selectedNationalityCode;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull;

    String initialPhone =
        user?.phone_number ?? CachedVariables.phone_number ?? '';
    String initialCountryCode = '+966';

    if (initialPhone.startsWith('+')) {
      RegExp regex = RegExp(r'^\+(\d{1,3})');
      Match? match = regex.firstMatch(initialPhone);
      if (match != null) {
        initialCountryCode = '+' + match.group(1)!;
        initialPhone = initialPhone.substring(match.group(0)!.length);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(countryCodeProvider.notifier).setCountryCode(initialCountryCode);
    });

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: initialPhone);
    _emailController = TextEditingController(
      text: user?.email ?? CachedVariables.email ?? '',
    );
    _selectedNationalityCode = user?.nationality;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = CachedVariables.userId;
    if (userId == null) return;

    setState(() => _isSaving = true);

    final success = await ProfileRepository.updateUser(
      userId: userId,
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      number: _phoneController.text.trim().isNotEmpty
          ? '${ref.read(countryCodeProvider)}${_phoneController.text.trim()}'
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      nationality: _selectedNationalityCode,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      // Update cached variables
      CachedVariables.userName = _nameController.text.trim();
      CachedVariables.phone_number = _phoneController.text.trim();
      CachedVariables.email = _emailController.text.trim();

      // Update the auth state so the UI refreshes
      final currentUser = ref.read(authControllerProvider).valueOrNull;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          name: _nameController.text.trim(),
          phone_number: _phoneController.text.trim().isNotEmpty
              ? '${ref.read(countryCodeProvider)}${_phoneController.text.trim()}'
              : '',
          email: _emailController.text.trim(),
          nationality: _selectedNationalityCode,
          missingFields: (currentUser.missingFields ?? []).where((field) {
            if (field == 'phone_number' &&
                _phoneController.text.trim().isNotEmpty) {
              return false;
            }
            if (field == 'email' && _emailController.text.trim().isNotEmpty) {
              return false;
            }
            return true;
          }).toList(),
        );
        ref.read(authControllerProvider.notifier).updateUser(updatedUser);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profileUpdatedSuccessfully'.tr()),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home page after successful update
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profileUpdateFailed'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddAddressDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const AddEditAddressScreen()),
    );

    if (result != null && mounted) {
      ref.invalidate(userAddressesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('addressSavedSuccessfully'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteAddress(int addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('deleteAddressTitle'.tr()),
        content: Text('deleteAddressConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ProfileRepository.deleteAddress(addressId);
      if (success && mounted) {
        ref.invalidate(userAddressesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('addressDeletedSuccessfully'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final addressesAsync = ref.watch(userAddressesProvider);
    final countryCode = ref.watch(countryCodeProvider);
    final missingFields = user?.missingFields ?? [];
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'completeProfile'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: themeColor.withOpacity(0.1),
                      child: Text(
                        user?.name?.isNotEmpty == true
                            ? user!.name!.substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                    gapH16,
                    Text(
                      user?.name ?? AppStrings.name.tr(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    gapH4,
                    Text(
                      user?.phone_number ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              gapH24,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Missing fields banner
                      if (missingFields.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                              ),
                              gapW8,
                              Expanded(
                                child: Text(
                                  'missingFieldsBanner'.tr(),
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        gapH16,
                      ],

                      // ─── Personal Info Section ───
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader(
                            icon: Icons.person_outline,
                            title: 'personalInfo'.tr(),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFieldLabel('name'.tr()),
                                  WhiteRoundedTextFormField(
                                    controller: _nameController,
                                    keyboardType: TextInputType.name,
                                    hintText: 'name',
                                    validator: (v) => null,
                                    borderSide: BorderSide(
                                      color: missingFields.contains('name')
                                          ? Colors.orange
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  gapH12,

                                  _buildFieldLabel('phoneNumber'.tr()),
                                  PhoneNumberField(
                                    controller: _phoneController,
                                    initialCountryCode: countryCode,
                                    onCountryChanged: (country) {
                                      if (country.dialCode != null) {
                                        ref
                                            .read(countryCodeProvider.notifier)
                                            .setCountryCode(country.dialCode!);
                                      }
                                    },
                                    validator: (v) => null,
                                    hintText: '5XXXXXXXXXX',
                                    borderSide: BorderSide(
                                      color:
                                          missingFields.contains('phone_number')
                                          ? Colors.orange
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  gapH12,

                                  _buildFieldLabel('email'.tr()),
                                  WhiteRoundedTextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    hintText: 'email',
                                    validator: (v) => null,
                                    borderSide: BorderSide(
                                      color: missingFields.contains('email')
                                          ? Colors.orange
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  gapH12,

                                  _buildFieldLabel('nationality'.tr()),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 400,
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedNationalityCode,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                      ),
                                      hint: Text('nationality'.tr()),
                                      items: countries.map((c) {
                                        final flag = SocketUser.getFlagEmoji(
                                          c.code,
                                        );
                                        final isAr =
                                            context.locale.languageCode == 'ar';
                                        final name = isAr ? c.nameAr : c.nameEn;
                                        return DropdownMenuItem<String>(
                                          value: c.code,
                                          child: Text('$flag  $name'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(
                                          () =>
                                              _selectedNationalityCode = value,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          gapH24,

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionHeader(
                                    icon: Icons.location_on_outlined,
                                    title: 'addressesSection'.tr(),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showAddAddressDialog,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text('addAddress'.tr()),
                                  ),
                                ],
                              ),
                              if (missingFields.contains('address'))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'noAddressesYet'.tr(),
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              gapH8,

                              addressesAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, _) => Text('Error: $e'),
                                data: (addresses) {
                                  if (addresses.isEmpty) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.02,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.location_off,
                                              size: 48,
                                              color: Colors.grey.shade400,
                                            ),
                                            gapH8,
                                            Text(
                                              'noAddressesYet'.tr(),
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: addresses.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(),
                                        itemBuilder: (ctx, index) {
                                          final addr = addresses[index];
                                          return _buildAddressCard(addr);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      gapH24,

                      // Save button
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                                  'save'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      gapH32,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2D4739)),
        gapW8,
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAddressCard(AddressModel addr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D4739).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF2D4739),
              size: 20,
            ),
          ),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      addr.label ?? addr.name ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (addr.isDefault == true) ...[
                      gapW8,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'defaultAddress'.tr(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                gapH4,
                Text(
                  '${addr.address ?? ''}, ${addr.city ?? ''}, ${addr.country ?? ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (addr.mobile != null) ...[
                  gapH2,
                  Text(
                    addr.mobile!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
            onPressed: () {
              if (addr.id != null) {
                _deleteAddress(addr.id!);
              }
            },
          ),
        ],
      ),
    );
  }
}
