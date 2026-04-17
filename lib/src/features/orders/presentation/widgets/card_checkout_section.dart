import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings/app_strings.dart';
import '../../domain/saved_payment_method_model.dart';

class CardCheckoutSection extends StatelessWidget {
  const CardCheckoutSection({
    super.key,
    required this.theme,
    required this.onStartGeideaCheckout,
    required this.savedPaymentMethods,
    required this.onAddCard,
    required this.onSetDefault,
    required this.onDeactivate,
    required this.showSaveCardFeatures,
    required this.saveCardForFutureUse,
    required this.onSaveCardForFutureUseChanged,
    this.isLoading = false,
    this.isLoadingSavedMethods = false,
    this.isSavingCard = false,
  });

  final ThemeData theme;
  final Future<void> Function() onStartGeideaCheckout;
  final Future<void> Function() onAddCard;
  final Future<void> Function(int methodId) onSetDefault;
  final Future<void> Function(int methodId) onDeactivate;
  final bool showSaveCardFeatures;
  final List<SavedPaymentMethodModel> savedPaymentMethods;
  final bool saveCardForFutureUse;
  final ValueChanged<bool> onSaveCardForFutureUseChanged;
  final bool isLoading;
  final bool isLoadingSavedMethods;
  final bool isSavingCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSaveCardFeatures) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.savedPaymentMethods.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: isSavingCard
                          ? null
                          : () async {
                              await onAddCard();
                            },
                      icon: isSavingCard
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_card_outlined, size: 18),
                      label: Text(AppStrings.addCard.tr()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoadingSavedMethods)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (savedPaymentMethods.isEmpty)
                  Text(
                    AppStrings.noSavedPaymentMethods.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  )
                else
                  Column(
                    children: savedPaymentMethods.map((method) {
                      final expiryLabel = method.expiryLabel;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: method.isDefault
                                ? theme.colorScheme.primary
                                : theme.dividerColor.withOpacity(0.3),
                          ),
                          color: method.isDefault
                              ? theme.colorScheme.primaryContainer.withOpacity(0.08)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.credit_card, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    method.maskedLabel,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (method.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      AppStrings.defaultCard.tr(),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (expiryLabel.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '${AppStrings.expiryDate.tr()}: $expiryLabel',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (!method.isDefault)
                                  TextButton(
                                    onPressed: () async {
                                      await onSetDefault(method.id);
                                    },
                                    child: Text(AppStrings.setAsDefault.tr()),
                                  ),
                                TextButton(
                                  onPressed: () async {
                                    await onDeactivate(method.id);
                                  },
                                  child: Text(AppStrings.removeCard.tr()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: saveCardForFutureUse,
            onChanged: isLoading
                ? null
                : (value) {
                    onSaveCardForFutureUseChanged(value);
                  },
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.saveCardForFutureUse.tr()),
          ),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    await onStartGeideaCheckout();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(AppStrings.cardPayment.tr()),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.geideaCheckoutPreparing.tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}
