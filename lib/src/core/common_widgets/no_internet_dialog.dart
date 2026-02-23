import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants/app_strings/app_strings.dart';
import 'primary_button.dart';

class NoInternetDialog extends StatelessWidget {
  const NoInternetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noInternetConnection.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.checkInternetConnection.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: AppStrings.ok.tr(),
                isLoading: false,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
