/// {@category Components}
///
/// A standardized modal alert for notifying users of network connectivity loss.
/// 
/// [NoInternetDialog] provides a prominent, non-dismissible (via tap-outside) 
/// barrier that forces the user to acknowledge their offline state. Use this 
/// component when a critical action fails due to network unavailability.
/// 
/// Design Specs:
/// - **Icon**: Red `wifi_off_rounded` for immediate semantic recognition.
/// - **Geometry**: 16.0 border radius consistent with the [CustomCard] token.
/// - **Action**: Features a full-width [PrimaryButton] for dismissal.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants/app_strings/app_strings.dart';
import 'primary_button.dart';

/// A modal dialog that communicates a "No Internet Connection" state.
class NoInternetDialog extends StatelessWidget {
  /// Creates a [NoInternetDialog].
  const NoInternetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevents full-screen height
          children: [
            // ── Primary Visual Logic ─────────────────────────────────────────
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            
            // ── Headline ─────────────────────────────────────────────────────
            Text(
              AppStrings.noInternetConnection.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // ── Sub-headline ─────────────────────────────────────────────────
            Text(
              AppStrings.checkInternetConnection.tr(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // ── Action Layer ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: AppStrings.ok.tr(),
                isLoading: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

