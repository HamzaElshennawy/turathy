import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

/// Favorite, share, and WhatsApp sit beside the lot number, never on the photo.
class LotActionRow extends StatelessWidget {
  const LotActionRow({
    super.key,
    required this.watched,
    required this.onShare,
    this.onWatch,
    this.onWhatsApp,
  });

  final bool watched;
  final VoidCallback onShare;
  final VoidCallback? onWatch;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onWatch != null)
          _ActionButton(
            tooltip: AppStrings.watchlist.tr(),
            icon: watched ? Icons.favorite_rounded : Icons.favorite_border,
            onPressed: onWatch!,
          ),
        _ActionButton(
          tooltip: AppStrings.shareItem.tr(),
          icon: Icons.ios_share_rounded,
          onPressed: onShare,
        ),
        if (onWhatsApp != null)
          _ActionButton(
            tooltip: AppStrings.whatsApp.tr(),
            asset: 'assets/icons/whats.png',
            onPressed: onWhatsApp!,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.asset,
  }) : assert(icon != null || asset != null);

  final String tooltip;
  final IconData? icon;
  final String? asset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget mark = asset != null
        ? Image.asset(
            asset!,
            width: 22,
            height: 22,
            semanticLabel: tooltip,
          )
        : Icon(icon!, size: 22);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      icon: mark,
    );
  }
}
