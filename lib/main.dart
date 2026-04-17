import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/app_root.dart';

import 'src/core/helper/cache/cache_helper.dart';
import 'src/core/helper/cache/cached_keys.dart';
import 'src/core/helper/cache/cached_variables.dart';
import 'src/core/helper/dio/dio_helper.dart';
import 'src/core/helper/fcm/fcm_service.dart';
import 'src/features/orders/utils/payment_debug_logger.dart';
import 'src/features/profile/data/shared_preference_theme_repo.dart';

void main() async {
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  DioHelper.init();
  CacheHelper.init();
  await LocalStorageThemeRepo.getTheme();
  CachedVariables.lang = await CacheHelper.getData(key: CachedKeys.lang);

  // Initialize FCM service
  fcmService.initialize();

  PaymentDebugLogger.info('Payment debug logging initialized', data: {
    'enabled': PaymentDebugLogger.enabled,
  });

  registerErrorHandler();
  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en', ''), Locale('ar', '')],
        path: 'assets/lang',
        child: const App(),
      ),
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

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
