import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/share/item_share_helper.dart';

Future<void> showItemShareSheet({
  required BuildContext context,
  required String title,
  required String url,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.shareItem.tr(),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                title: Text(AppStrings.shareWhatsApp.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ItemShareHelper.shareWhatsApp(title: title, url: url);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms_outlined),
                title: Text(AppStrings.shareSms.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ItemShareHelper.shareSms(title: title, url: url);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(AppStrings.copyLink.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ItemShareHelper.copyLink(url);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.linkCopied.tr())),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(AppStrings.shareMore.tr()),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ItemShareHelper.shareSystem(title: title, url: url);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
