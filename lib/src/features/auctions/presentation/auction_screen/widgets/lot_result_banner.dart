import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/helper/lot_result_status.dart';

/// Compact, non-blocking lot-end card. Must never be a modal over bidding.
class LotResultBanner extends StatelessWidget {
  final LotResultKind kind;
  final VoidCallback? onDismiss;

  const LotResultBanner({
    super.key,
    required this.kind,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (kind == LotResultKind.none) return const SizedBox.shrink();

    final color = lotResultColor(kind);
    final label = lotResultStringKey(kind).tr();

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(lotResultIcon(kind), color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: Icon(Icons.close, size: 20, color: color),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}
