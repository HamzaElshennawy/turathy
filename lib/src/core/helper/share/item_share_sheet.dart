import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/share/item_share_helper.dart';

const Color _kBrand = Color(0xFF2D4739);

/// Modern horizontal share sheet (WhatsApp / SMS / copy / system).
Future<void> showItemShareSheet({
  required BuildContext context,
  required String title,
  required String url,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.shareItem.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kBrand,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ShareAction(
                    key: const Key('share_whatsapp'),
                    label: AppStrings.shareWhatsApp.tr(),
                    icon: Icons.chat_rounded,
                    background: const Color(0xFF25D366),
                    foreground: Colors.white,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await ItemShareHelper.shareWhatsApp(
                        title: title,
                        url: url,
                      );
                      if (result == ShareLaunchResult.fellBackToSystem &&
                          context.mounted) {
                        _toast(context, AppStrings.shareOpenedSystem.tr());
                      }
                    },
                  ),
                  _ShareAction(
                    key: const Key('share_sms'),
                    label: AppStrings.shareSms.tr(),
                    icon: Icons.sms_rounded,
                    background: const Color(0xFFE8F0EC),
                    foreground: _kBrand,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await ItemShareHelper.shareSms(
                        title: title,
                        url: url,
                      );
                      if (result == ShareLaunchResult.fellBackToSystem &&
                          context.mounted) {
                        _toast(context, AppStrings.shareOpenedSystem.tr());
                      }
                    },
                  ),
                  _ShareAction(
                    key: const Key('share_copy'),
                    label: AppStrings.copyLink.tr(),
                    icon: Icons.link_rounded,
                    background: const Color(0xFFE8F0EC),
                    foreground: _kBrand,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ItemShareHelper.copyLink(url);
                      if (context.mounted) {
                        _toast(context, AppStrings.linkCopied.tr());
                      }
                    },
                  ),
                  _ShareAction(
                    key: const Key('share_more'),
                    label: AppStrings.shareMore.tr(),
                    icon: Icons.ios_share_rounded,
                    background: _kBrand,
                    foreground: Colors.white,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ItemShareHelper.shareSystem(
                        title: title,
                        url: url,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _ShareAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _ShareAction({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: foreground, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2E22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
