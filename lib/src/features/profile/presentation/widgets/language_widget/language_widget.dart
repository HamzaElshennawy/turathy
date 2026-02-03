import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/helper/cache/cache_helper.dart';
import '../../../../../core/helper/cache/cached_keys.dart';
import '../../../../../core/helper/cache/cached_variables.dart';
import '../../../controller/language_controller.dart';

class LanguageWidget extends ConsumerWidget {
  const LanguageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cubit = ref.watch(languageControllerProvider.notifier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          itemWidget(
            text: 'English',
            onTap: () async {
              cubit.changeLanguage('en');
              final localization = EasyLocalization.of(context);
              if (localization != null) {
                context.setLocale(const Locale("en", ""));
                await CacheHelper.setData(key: CachedKeys.lang, value: "en");
                CachedVariables.lang = await CacheHelper.getData(key: "lang");
              }
            },
            isSelected:
                ref.read(languageControllerProvider) == 'en' ? true : false,
            context: context,
          ),
          itemWidget(
            text: 'العربية',
            onTap: () async {
              cubit.changeLanguage('ar');
              final localization = EasyLocalization.of(context);
              if (localization != null) {
                context.setLocale(const Locale("ar", ""));
                await CacheHelper.setData(key: CachedKeys.lang, value: "ar");
                CachedVariables.lang = await CacheHelper.getData(key: "lang");
              }
            },
            isSelected:
                ref.read(languageControllerProvider) == 'en' ? false : true,
            context: context,
          )
        ],
      ),
    );
  }

  Widget itemWidget({
    required String text,
    required void Function()? onTap,
    required bool isSelected,
    required BuildContext context,
  }) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: isSelected ? Theme.of(context).colorScheme.primary : null),
          child: Text(
            text,
            style: GoogleFonts.inter(
                color:
                    isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                fontWeight: FontWeight.w500,
                fontSize: 14),
          ),
        ),
      );
}
