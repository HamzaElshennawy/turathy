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
    await secureStorage.write(key: key, value: value);
  }

  static Future<String?> getData({required String key}) async {
    return await secureStorage.read(key: key);
  }

  static Future<void> deleteData({required String key}) async {
    await secureStorage.delete(key: key);
  }
}
