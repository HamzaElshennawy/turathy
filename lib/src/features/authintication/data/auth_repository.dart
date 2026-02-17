import '../../../core/constants/app_functions/app_functions.dart';
import '../../../core/helper/cache/cache_helper.dart';
import '../../../core/helper/cache/cached_keys.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../domain/user_model.dart';

class AuthRepository {
  static Future<UserModel> signIn(String phone, String password) async {
    final result = await DioHelper.postData(
      url: EndPoints.login,
      data: {'phone_number': phone, 'password': password},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      final user = UserModel.fromJson(result.data['data']);

      // Cache token
      final token = result.data['token'] ?? result.data['data']['token'];
      if (token != null) {
        await CacheHelper.setData(key: CachedKeys.fcmToken, value: token);
        CachedVariables.token = token;
      }

      await cacheData(user.copyWith(password: password, phone_number: phone));
      return user;
    } else {
      AppFunctions.logPrint(
        message: 'code signIn ${result.statusCode} $result ',
      );
      String message =
          result.data['error'] ?? 'An error occurred while signing in';
      throw AuthException(message, result.statusCode);
    }
  }

  static Future<UserModel> googleSignIn(String token) async {
    final result = await DioHelper.postData(
      url:
          'auth/google-login', // EndPoints.googleLogin (I should add this to EndPoints ideally but hardcoding for now or I'll update EndPoints too)
      data: {'token': token},
    );

    if (result.statusCode == 200 || result.statusCode == 201) {
      final user = UserModel.fromJson(result.data['data']);

      // Cache token
      final token = result.data['token'] ?? result.data['data']['token'];
      if (token != null) {
        await CacheHelper.setData(key: CachedKeys.fcmToken, value: token);
        CachedVariables.token = token;
      }

      await cacheData(user); // No password to cache
      return user;
    } else {
      AppFunctions.logPrint(
        message: 'code googleSignIn ${result.statusCode} $result ',
      );
      String message =
          result.data['error'] ??
          'An error occurred while signing in with Google';
      throw AuthException(message, result.statusCode);
    }
  }

  static Future<UserModel> getUser(int id) async {
    final result = await DioHelper.getData(
      url: EndPoints.getUser(id),
      token: CachedVariables.token,
    );

    if (result.statusCode == 200) {
      final user = UserModel.fromJson(result.data['data']);
      await cacheData(user);
      return user;
    } else {
      String message =
          result.data['error'] ?? 'An error occurred while fetching user data';
      throw AuthException(message, result.statusCode);
    }
  }

  static Future<bool> createUser(UserModel user) async {
    final result = await DioHelper.postData(
      url: EndPoints.userSignup,
      data: user.toJson(),
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      String message = result.data['message'].toString();
      AppFunctions.logPrint(message: 'code createUser ${result.statusCode} ');
      throw AuthException(message, result.statusCode);
    }
  }

  static Future<bool> verifyOtp({
    required String number,
    required String otp,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.verifyOTP,
      data: {'number': number, 'otp': otp},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      final message =
          result.data['message']?.toString() ?? 'OTP verification failed';
      throw AuthException(message, result.statusCode);
    }
  }

  static Future<bool> resendOtp({required String number}) async {
    final result = await DioHelper.postData(
      url: EndPoints.resendOTP,
      data: {'number': number},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      final message = result.data['message']?.toString() ?? 'OTP resend failed';
      throw AuthException(message, result.statusCode);
    }
  }

  static Future<bool> requestOtp({required String number}) async {
    final result = await DioHelper.postData(
      url: EndPoints.requestOTP,
      data: {'number': number},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      final message =
          result.data['message']?.toString() ?? 'OTP request failed';
      throw AuthException(message, result.statusCode);
    }
  }

  static Future<bool> changePassword({
    required String number,
    required String otp,
    required String password,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.changePassword,
      data: {'number': number, 'otp': otp, 'password': password},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      final message =
          result.data['message']?.toString() ?? 'Password change failed';
      throw AuthException(message, result.statusCode);
    }
  }

  // static Future<bool> signOut() async {
  //   final result = await DioHelper.postData(
  //       url: EndPoints.logout, token: CachedVariables.token);
  //   AppFunctions.logPrint(
  //       message: 'code SignOut ${result.statusCode.toString()}');
  //   if (result.statusCode == 200) {
  //     return true;
  //   } else {
  //     String message =
  //         result.data['error'] ?? 'An error occurred while signing out';
  //     throw AuthException(message, result.statusCode);
  //   }
  // }

  // // delete account
  // static Future<bool> deleteAccount() async {
  //   final result = await DioHelper.deleteData(
  //       url: EndPoints.deleteAccount, token: CachedVariables.token);
  //   if (result.statusCode == 200) {
  //     return true;
  //   } else {
  //     String message = result.data.toString();
  //     throw AuthException(message, result.statusCode);
  //   }
  // }

  // local storage
  static Future<void> cacheData(UserModel? user) async {
    if (user != null) {
      if (user.id != null) {
        await CacheHelper.setData(
          key: CachedKeys.userId,
          value: user.id.toString(),
        ).then((value) async {
          CachedVariables.userId = int.tryParse(
            await CacheHelper.getData(key: CachedKeys.userId) ?? '',
          );
        });
      }
      if (user.phone_number != null) {
        await CacheHelper.setData(
          key: CachedKeys.phone_number,
          value: user.phone_number!,
        ).then((value) async {
          CachedVariables.phone_number = await CacheHelper.getData(
            key: CachedKeys.phone_number,
          );
        });
      }
      if (user.password != null) {
        await CacheHelper.setData(
          key: CachedKeys.password,
          value: user.password!,
        ).then((value) async {
          CachedVariables.password = await CacheHelper.getData(
            key: CachedKeys.password,
          );
        });
      }
    }
  }

  static Future<void> getLocalDetails() async {
    CachedVariables.userId = int.tryParse(
      await CacheHelper.getData(key: CachedKeys.userId) ?? '',
    );
    CachedVariables.phone_number = await CacheHelper.getData(
      key: CachedKeys.phone_number,
    );
    CachedVariables.password = await CacheHelper.getData(
      key: CachedKeys.password,
    );
    CachedVariables.onBoard = await CacheHelper.getData(
      key: CachedKeys.onBoard,
    );
    CachedVariables.token = await CacheHelper.getData(key: CachedKeys.fcmToken);
  }

  static Future<void> clearLocalDetails() async {
    CachedVariables.token = null;
    CachedVariables.userId = null;
    CachedVariables.email = null;
    CachedVariables.phone_number = null;
    CachedVariables.password = null;
    await CacheHelper.deleteData(key: CachedKeys.userId);
    await CacheHelper.deleteData(key: CachedKeys.phone_number);
    await CacheHelper.deleteData(key: CachedKeys.password);
    await CacheHelper.deleteData(key: CachedKeys.onBoard);
    await CacheHelper.deleteData(key: CachedKeys.fcmToken);
  }
}

class AuthException implements Exception {
  final String message;
  final int? code;

  AuthException(this.message, this.code);

  @override
  String toString() {
    return message + (code != null ? ' code: $code' : '');
  }
}
