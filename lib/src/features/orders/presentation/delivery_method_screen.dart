import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../data/shipping_settings_repository.dart';
import '../domain/shipping_setting_model.dart';
import '../../addresses/presentation/address_selection_screen.dart';

class DeliveryMethodData {
  final ShippingSettingModel method;
  final bool combineShipments;

  DeliveryMethodData({
    required this.method,
    this.combineShipments = false,
  });
}

class DeliveryMethodScreen extends ConsumerStatefulWidget {
  const DeliveryMethodScreen({super.key});

  @override
  ConsumerState<DeliveryMethodScreen> createState() => _DeliveryMethodScreenState();
}

class _DeliveryMethodScreenState extends ConsumerState<DeliveryMethodScreen> {
  ShippingSettingModel? _selectedMethod;
  bool _combineShipments = false;

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(shippingSettingsFutureProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.deliveryMethod.tr(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: asyncSettings.when(
        data: (settings) {
          if (settings.isEmpty) {
            return const Center(child: Text('No delivery methods available.'));
          }

          final isArabic = context.locale.languageCode == 'ar';

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: settings.length,
                  itemBuilder: (context, index) {
                    final method = settings[index];
                    final isSelected = _selectedMethod?.key == method.key;
                    final isShipping = method.key != 'PICKUP';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<ShippingSettingModel>(
                            value: method,
                            groupValue: _selectedMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedMethod = value;
                                if (!isShipping) {
                                  _combineShipments = false;
                                }
                              });
                            },
                            activeColor: const Color(0xFF1B5E20),
                            title: Text(
                              isArabic ? method.labelAr : method.labelEn,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              method.fee == 0
                                  ? AppStrings.free.tr()
                                  : '${method.fee} SAR',
                              style: TextStyle(
                                color: method.fee == 0 ? Colors.green : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isSelected && isShipping)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _combineShipments,
                                        onChanged: (val) {
                                          setState(() {
                                            _combineShipments = val ?? false;
                                          });
                                        },
                                        activeColor: const Color(0xFF1B5E20),
                                      ),
                                      Expanded(
                                        child: Text(
                                          AppStrings.combineShipments.tr(),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_combineShipments)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
                                      child: Text(
                                        AppStrings.combineShipmentsMessage.tr(),
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedMethod == null
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                DeliveryMethodData(
                                  method: _selectedMethod!,
                                  combineShipments: _combineShipments,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        AppStrings.continueText.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading delivery methods: $error')),
      ),
    );
  }
}

final shippingSettingsFutureProvider = FutureProvider.autoDispose<List<ShippingSettingModel>>((ref) async {
  return ref.watch(shippingSettingsRepositoryProvider).getShippingSettings();
});
