import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/settings/data/app_config_repository.dart';
import '../../constants/app_strings/app_strings.dart';

/// Support chat uses `https://wa.me/{digits}?text=` only.
Uri? supportWhatsAppUri(AppConfig config, {int? lotNumber}) {
  if (!config.whatsappEnabled) return null;
  final digits = config.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  final base = config.whatsappDefaultMessage.trim();
  final text = lotNumber == null
      ? base
      : (base.isEmpty ? 'رقم البند: $lotNumber' : '$base\nرقم البند: $lotNumber');
  return Uri.https('wa.me', '/$digits', {'text': text});
}

Future<void> openSupportWhatsApp(
  BuildContext context,
  AppConfig config, {
  int? lotNumber,
}) async {
  final uri = supportWhatsAppUri(config, lotNumber: lotNumber);
  if (uri == null) return;
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.whatsappNotInstalled.tr())),
    );
  }
}
