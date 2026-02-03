import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/theme_model.dart';

class ThemingService extends StateNotifier<ThemeModel> {
  Future _init() async {}

  ThemingService() : super(ThemeModel()) {
    _init();
  }
}
