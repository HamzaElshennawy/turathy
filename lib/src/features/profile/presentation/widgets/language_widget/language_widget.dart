import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/helper/cache/cache_helper.dart';
import '../../../../../core/helper/cache/cached_keys.dart';
import '../../../../../core/helper/cache/cached_variables.dart';
import '../../../../../core/helper/locale/app_locale_sync.dart';
import '../../../../authintication/presentation/auth_controller.dart';
import '../../../controller/language_controller.dart';

class LanguageWidget extends ConsumerWidget {
  const LanguageWidget({super.key});

  Future<void> _applyLanguage(
    BuildContext context,
    WidgetRef ref,
    String languageCode,
  ) async {
    final cubit = ref.read(languageControllerProvider.notifier);
    cubit.changeLanguage(languageCode);
    final localization = EasyLocalization.of(context);
    if (localization == null) return;

    await context.setLocale(Locale(languageCode, ''));
    await CacheHelper.setData(key: CachedKeys.lang, value: languageCode);
    CachedVariables.lang = languageCode;

    final user = ref.read(authControllerProvider).valueOrNull;
    final ok = await AppLocaleSync.syncPreferredLanguageToBackend(force: true);
    if (ok && user != null) {
      ref.read(authControllerProvider.notifier).updateUser(
            user.copyWith(
              preferredLanguage: AppLocaleSync.preferredLanguageApi,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: Theme.of(context).colorScheme.primaryContainer.withValues(
              alpha: 1,
            ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          itemWidget(
            text: 'English',
            onTap: () => _applyLanguage(context, ref, 'en'),
            isSelected: ref.read(languageControllerProvider) == 'en',
            context: context,
          ),
          itemWidget(
            text: 'العربية',
            onTap: () => _applyLanguage(context, ref, 'ar'),
            isSelected: ref.read(languageControllerProvider) != 'en',
            context: context,
          ),
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
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : null,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      );
}
