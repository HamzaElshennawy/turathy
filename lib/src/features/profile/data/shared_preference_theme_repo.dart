import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cache_helper.dart';
import '../domain/theme_model.dart';

class LocalStorageThemeRepo {
  static ThemeModel? currentTheme;

  static Future<ThemeModel?> getTheme() async {
    final stringTheme = await CacheHelper.getData(key: 'theme');

    if (stringTheme == null) {
      currentTheme = ThemeModel();
      return ThemeModel();
    } else {
      currentTheme = ThemeModel.fromMap(jsonDecode(stringTheme));
      return currentTheme;
    }
  }

  Future<void> setTheme(ThemeModel theme) async {
    await CacheHelper.setData(key: 'theme', value: jsonEncode(theme.toMap()));
  }
}

final localStorageThemeRepoProvider = Provider<LocalStorageThemeRepo>((ref) {
  return LocalStorageThemeRepo();
});
