import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/app_root.dart';

import 'src/core/helper/cache/cache_helper.dart';
import 'src/core/helper/cache/cached_keys.dart';
import 'src/core/helper/cache/cached_variables.dart';
import 'src/core/helper/dio/dio_helper.dart';
import 'src/features/profile/data/shared_preference_theme_repo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await DioHelper.init();
  await CacheHelper.init();
  await LocalStorageThemeRepo.getTheme();
  CachedVariables.lang = await CacheHelper.getData(key: CachedKeys.lang);
  registerErrorHandler();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', ''), Locale('ar', '')],
      path: 'assets/lang',
      child: const ProviderScope(child: App()),
    ),
  );
}

void registerErrorHandler() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    return true;
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('An error occurred'),
      ),
      body: Center(child: Text(details.toString())),
    );
  };
}
