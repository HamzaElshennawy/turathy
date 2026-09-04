import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/locale/app_locale_sync.dart';

void main() {
  tearDown(() {
    CachedVariables.lang = null;
  });

  test('preferredLanguageApi follows CachedVariables.lang', () {
    CachedVariables.lang = 'ar';
    expect(AppLocaleSync.isArabic, isTrue);
    expect(AppLocaleSync.preferredLanguageApi, 'AR');

    CachedVariables.lang = 'en';
    expect(AppLocaleSync.isArabic, isFalse);
    expect(AppLocaleSync.preferredLanguageApi, 'EN');
  });

  test('resolvePushText picks Arabic fields when app is Arabic', () {
    CachedVariables.lang = 'ar';
    final text = AppLocaleSync.resolvePushText(
      data: {
        'title_ar': 'فوز',
        'title_en': 'Won',
        'body_ar': 'مبروك',
        'body_en': 'Congrats',
      },
      fallbackTitle: 'fallback',
      fallbackBody: 'fallback-body',
    );
    expect(text.title, 'فوز');
    expect(text.body, 'مبروك');
  });

  test('resolvePushText picks English fields when app is English', () {
    CachedVariables.lang = 'en';
    final text = AppLocaleSync.resolvePushText(
      data: {
        'title_ar': 'فوز',
        'title_en': 'Won',
        'body_ar': 'مبروك',
        'body_en': 'Congrats',
      },
    );
    expect(text.title, 'Won');
    expect(text.body, 'Congrats');
  });
}
