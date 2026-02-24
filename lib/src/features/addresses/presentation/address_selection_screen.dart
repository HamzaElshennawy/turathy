import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../data/address_repository.dart';
import '../domain/user_address_model.dart';
import 'add_edit_address_screen.dart';

/// Screen that lets the user pick from saved addresses or add a new one.
/// Returns the selected [UserAddressModel] via `Navigator.pop`.
class AddressSelectionScreen extends ConsumerStatefulWidget {
  final int? preselectedAddressId;

  const AddressSelectionScreen({super.key, this.preselectedAddressId});

  @override
  ConsumerState<AddressSelectionScreen> createState() =>
      _AddressSelectionScreenState();
}

class _AddressSelectionScreenState
    extends ConsumerState<AddressSelectionScreen> {
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _selectedAddressId = widget.preselectedAddressId;
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.of(context).push<UserAddressModel>(
      MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
    );
    if (result != null && mounted) {
      final userId = CachedVariables.userId;
      if (userId != null) {
        ref.invalidate(userAddressesProvider(userId));
      }
      setState(() => _selectedAddressId = result.id);
    }
  }

  Future<void> _editAddress(UserAddressModel address) async {
    final result = await Navigator.of(context).push<UserAddressModel>(
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(address: address),
      ),
    );
    if (result != null && mounted) {
      final userId = CachedVariables.userId;
      if (userId != null) {
        ref.invalidate(userAddressesProvider(userId));
      }
      setState(() => _selectedAddressId = result.id);
    }
  }

  Future<void> _deleteAddress(UserAddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppStrings.deleteAddress.tr()),
        content: Text(address.displayLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.delete.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(addressRepositoryProvider).deleteAddress(address.id);
        final userId = CachedVariables.userId;
        if (userId != null) {
          ref.invalidate(userAddressesProvider(userId));
        }
        if (_selectedAddressId == address.id) {
          setState(() => _selectedAddressId = null);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.addressDeletedSuccessfully.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _confirmSelection(List<UserAddressModel> addresses) {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.selectAddress.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final selected = addresses.firstWhere((a) => a.id == _selectedAddressId);
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final userId = CachedVariables.userId;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.selectAddress.tr())),
        body: const Center(child: Text('Please sign in')),
      );
    }

    final addressesAsync = ref.watch(userAddressesProvider(userId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.selectAddress.tr()), elevation: 0),
      body: addressesAsync.when(
        data: (addresses) {
          // Auto-select default if nothing selected
          if (_selectedAddressId == null && addresses.isNotEmpty) {
            final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
            if (defaultAddr != null) {
              _selectedAddressId = defaultAddr.id;
            }
          }

          return Column(
            children: [
              // Add new address button
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: _addNewAddress,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.addNewAddress.tr(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (addresses.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.noAddressesSaved.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      final isSelected = addr.id == _selectedAddressId;
                      return _buildAddressCard(addr, isSelected, theme);
                    },
                  ),
                ),

              // Confirm button
              if (addresses.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _confirmSelection(addresses),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.continueToPayment.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userAddressesProvider(userId)),
                child: Text(AppStrings.retry.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    UserAddressModel address,
    bool isSelected,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = address.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.08)
              : theme.colorScheme.surface,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Address info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label ?? address.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.defaultAddress.tr(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.name,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    address.mobile,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.fullAddress,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Edit / Delete actions
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[500], size: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _editAddress(address);
                } else if (value == 'delete') {
                  _deleteAddress(address);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text(AppStrings.editAddress.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.deleteAddress.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
