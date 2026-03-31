import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheHelper {
  static late FlutterSecureStorage secureStorage;

  static void init() {
    secureStorage = const FlutterSecureStorage(
      iOptions: IOSOptions(),
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  static Future<void> setData({
    required String key,
    required String value,
  }) async {
    try {
      await secureStorage.write(key: key, value: value);
    } on PlatformException catch (e) {
      // iOS keychain error -25299: item already exists. Delete then retry.
      if (e.code == 'Unexpected security result code' ||
          e.message?.contains('-25299') == true) {
        await secureStorage.delete(key: key);
        await secureStorage.write(key: key, value: value);
      } else {
        rethrow;
      }
    }
  }

  static Future<String?> getData({required String key}) async {
    return await secureStorage.read(key: key);
  }

  static Future<void> deleteData({required String key}) async {
    await secureStorage.delete(key: key);
  }
}
