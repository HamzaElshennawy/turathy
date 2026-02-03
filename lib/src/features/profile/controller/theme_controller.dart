import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_preference_theme_repo.dart';
import '../domain/theme_model.dart';

class ThemeController extends StateNotifier<ThemeModel> {
  ThemeModel? currentTheme;
  final LocalStorageThemeRepo sharedPreferenceThemeRepo;

  ThemeController(this.sharedPreferenceThemeRepo, this.currentTheme)
      : super(currentTheme ?? ThemeModel());

  void setTheme(ThemeModel theme) {
    state = theme;
    sharedPreferenceThemeRepo.setTheme(theme);
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeModel>((ref) {
  final repo = ref.watch(localStorageThemeRepoProvider);

  return ThemeController(repo, LocalStorageThemeRepo.currentTheme);
});
