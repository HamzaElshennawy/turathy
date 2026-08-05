import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/profile/data/profile_repository.dart';

/// Keeps push/email language aligned with the in-app locale (ar ↔ AR, en ↔ EN).
class AppLocaleSync {
  AppLocaleSync._();

  /// Current UI language code (`ar` / `en`), default Arabic for this market.
  static String get uiLanguageCode {
    final raw = (CachedVariables.lang ?? 'ar').trim().toLowerCase();
    if (raw.startsWith('en')) return 'en';
    return 'ar';
  }

  static bool get isArabic => uiLanguageCode == 'ar';

  /// Backend `users.preferredLanguage` enum value.
  static String get preferredLanguageApi => isArabic ? 'AR' : 'EN';

  /// Sync app locale → backend when logged in (no-op if unchanged and [force] is false).
  static Future<bool> syncPreferredLanguageToBackend({
    String? profilePreferredLanguage,
    bool force = false,
  }) async {
    final userId = CachedVariables.userId;
    if (userId == null || CachedVariables.token == null) return false;

    final desired = preferredLanguageApi;
    final current = profilePreferredLanguage?.trim().toUpperCase();
    if (!force && current == desired) return true;

    return ProfileRepository.updateUser(
      userId: userId,
      preferredLanguage: desired,
    );
  }

  /// Pick push title/body from FCM data bilingual fields using app locale.
  static ({String title, String body}) resolvePushText({
    required Map<String, dynamic> data,
    String? fallbackTitle,
    String? fallbackBody,
  }) {
    final ar = isArabic;
    String pick(List<String> keys, String? fallback) {
      for (final key in keys) {
        final v = data[key]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return fallback?.trim() ?? '';
    }

    final title = ar
        ? pick(const ['title_ar', 'titleAr'], fallbackTitle)
        : pick(const ['title_en', 'titleEn'], fallbackTitle);
    final body = ar
        ? pick(const ['body_ar', 'bodyAr'], fallbackBody)
        : pick(const ['body_en', 'bodyEn'], fallbackBody);

    return (
      title: title.isNotEmpty ? title : (fallbackTitle ?? ''),
      body: body.isNotEmpty ? body : (fallbackBody ?? ''),
    );
  }
}
