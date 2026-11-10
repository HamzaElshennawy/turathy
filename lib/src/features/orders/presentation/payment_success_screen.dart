import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings/app_strings.dart';
import '../../main_screen_tab.dart';

class PaymentSuccessScreen extends ConsumerWidget {
  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
  });

  final int orderId;
  final double total;

  String _amountText() {
    final whole = total == total.truncateToDouble();
    return whole ? total.toStringAsFixed(0) : total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = context.locale.languageCode == 'ar' ? 'ر.س' : 'SAR';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.paymentReceivedTitle.tr())),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.paymentReceivedTitle.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.paymentThanks.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text(
                '${AppStrings.paymentOrderNumber.tr()} $orderId',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${AppStrings.paymentAmount.tr()} ${_amountText()} $currency',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.paymentNextStep.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.viewOrder.tr()),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(mainScreenTabIndexProvider.notifier).state = 0;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(AppStrings.backToHome.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
