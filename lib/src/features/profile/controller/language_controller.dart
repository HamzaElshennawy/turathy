import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cache_helper.dart';
import '../../../core/helper/cache/cached_keys.dart';
import '../../../core/helper/cache/cached_variables.dart';

class LanguageController extends StateNotifier<String> {
  LanguageController() : super(CachedVariables.lang ?? 'en');

  void changeLanguage(String language) {
    state = language;
    CacheHelper.setData(key: CachedKeys.lang, value: language);
    CachedVariables.lang = language;
  }
}

final languageControllerProvider =
    StateNotifierProvider<LanguageController, String>((ref) {
  return LanguageController();
});
