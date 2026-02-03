import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class ThemeModel {
  late ThemeMode mode;
  late FlexScheme theme;
  ThemeModel({this.mode = ThemeMode.light, this.theme = FlexScheme.jungle});
  ThemeModel.fromMap(Map<String, dynamic> map) {
    mode = map['mode'] == 'light' ? ThemeMode.light : ThemeMode.dark;
    theme = FlexScheme.values.firstWhere(
        (element) => element.name == map['theme'],
        orElse: () => FlexScheme.blueM3);
  }

  Map<String, String> toMap() {
    return {
      'mode': mode == ThemeMode.light ? 'light' : 'dark',
      'theme': theme.name,
    };
  }

  ThemeModel copyWith({
    ThemeMode? mode,
    FlexScheme? theme,
  }) {
    return ThemeModel(
      mode: mode ?? this.mode,
      theme: theme ?? this.theme,
    );
  }
}
