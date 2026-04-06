/// {@category Data}
///
/// Data repository for all authentication-related operations.
/// 
/// This repository acts as the single point of entry for:
/// - **API Interactions**: Login, Signup, OTP Verification, Password Changes.
/// - **Session Management**: Storing and retrieving tokens and user IDs from local cache.
/// - **Third-Party Auth**: Direct integration with Google Sign-In.
import 'dart:convert';
import 'dart:developer';

import '../../../core/constants/app_functions/app_functions.dart';
import '../../../core/helper/cache/cache_helper.dart';
import '../../../core/helper/cache/cached_keys.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../domain/user_model.dart';

/// Internal utility to ensure a Dio response's data is a [Map].
/// 
/// If Dio returns a raw JSON string instead of a parsed Map, this helper 
/// decodes it. Returns an empty map as a fallback to prevent runtime crashes.
Map<String, dynamic> _ensureMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is String) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return {};
}

/// Manages authentication state and persistence.
class AuthRepository {
  /// Authenticates a user using phone and password.
  /// 
  /// On success:
  /// - Caches the auth token.
  /// - Persists user details locally.
  /// - Returns a map containing the [UserModel] and navigation flags.
  /// 
  /// Throws [AuthException] on failure.
  static Future<Map<String, dynamic>> signIn(
    String phone,
    String password,
  ) async {
    final result = await DioHelper.postData(
      url: EndPoints.login,
      data: {'phone_number': phone, 'password': password},
    );
    final body = _ensureMap(result.data);
    
    if (result.statusCode == 200 || result.statusCode == 201) {
      final data = _ensureMap(body['data']);
      final user = UserModel.fromJson(data);

      final token = body['token'] ?? data['token'];
      if (token != null) {
        await CacheHelper.setData(key: CachedKeys.authToken, value: token);
        CachedVariables.token = token;
      }

      // Store credentials for auto-login on next app restart.
      await cacheData(user.copyWith(password: password, phone_number: phone));

      return {
        'user': user,
        'status': body['status'] ?? 'success',
        'isProfileComplete': data['isProfileComplete'] ?? true,
        'missingFields': data['missingFields'] ?? [],
      };
    } else {
      AppFunctions.logPrint(message: 'signIn error: ${result.statusCode}');
      String message = body['message']?.toString() ??
          body['error']?.toString() ??
          'An error occurred while signing in';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Verifies a Google ID token with the backend.
  /// 
  /// This method is called after the client successfully signs in via 
  /// the Google SDK.
  static Future<UserModel> googleSignIn(String token) async {
    final result = await DioHelper.postData(
      url: 'auth/google-login',
      data: {'token': token},
    );

    final body = _ensureMap(result.data);
    if (result.statusCode == 200 || result.statusCode == 201) {
      final data = _ensureMap(body['data']);
      final user = UserModel.fromJson(data);

      final token = body['token'] ?? data['token'];
      if (token != null) {
        await CacheHelper.setData(key: CachedKeys.authToken, value: token);
        CachedVariables.token = token;
      }

      await cacheData(user);
      // Mark as Google account to trigger silent re-auth instead of password login.
      await CacheHelper.setData(key: CachedKeys.isGoogleSignIn, value: 'true');
      CachedVariables.isGoogleSignIn = true;
      return user;
    } else {
      String message = body['error']?.toString() ??
          'An error occurred while signing in with Google';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Fetches fresh user data from the backend.
  static Future<UserModel> getUser(int id) async {
    final result = await DioHelper.getData(
      url: EndPoints.getUser(id),
      token: CachedVariables.token,
    );

    final body = _ensureMap(result.data);
    if (result.statusCode == 200) {
      final user = UserModel.fromJson(_ensureMap(body['data']));
      await cacheData(user);
      return user;
    } else {
      String message = body['error']?.toString() ?? 'Failed to fetch user data';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Registers a new user account.
  /// 
  /// Returns registration status and identifying information (userId).
  /// Subsequent verification (OTP) is usually required.
  static Future<Map<String, dynamic>> createUser(UserModel user) async {
    final result = await DioHelper.postData(
      url: EndPoints.userSignup,
      data: user.toJson(),
    );
    final body = _ensureMap(result.data);
    if (result.statusCode == 200 || result.statusCode == 201) {
      final data = _ensureMap(body['data']);
      return {
        'status': body['status'] ?? 'success',
        'userId': data['userId'],
        'isProfileComplete': data['isProfileComplete'] ?? false,
        'missingFields': data['missingFields'] ?? [],
        'message': data['message'],
      };
    } else {
      String message = body['message']?.toString() ??
          body['error']?.toString() ??
          'Signup failed';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Validates a One-Time Password for a specific phone number.
  /// 
  /// If successfully verified, the user session is initialized.
  static Future<UserModel> verifyOtp({
    required String number,
    required String otp,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.verifyOTP,
      data: {'number': number, 'otp': otp},
    );
    final body = _ensureMap(result.data);
    if (result.statusCode == 200 || result.statusCode == 201) {
      final data = _ensureMap(body['data']);
      final user = UserModel.fromJson(data);

      final token = body['token'] ?? data['token'];
      if (token != null) {
        await CacheHelper.setData(key: CachedKeys.authToken, value: token);
        CachedVariables.token = token;
      }

      await cacheData(user.copyWith(phone_number: number));
      return user;
    } else {
      final message = body['message']?.toString() ?? 'OTP verification failed';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Requests a new OTP code to be sent to the user's phone.
  static Future<bool> resendOtp({required String number}) async {
    final result = await DioHelper.postData(
      url: EndPoints.resendOTP,
      data: {'number': number},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      final body = _ensureMap(result.data);
      final message = body['message']?.toString() ?? 'OTP resend failed';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Triggers the OTP flow (e.g. for registration or password reset).
  static Future<bool> requestOtp({required String number}) async {
    final result = await DioHelper.postData(
      url: EndPoints.requestOTP,
      data: {'number': number},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      final body = _ensureMap(result.data);
      final message = body['message']?.toString() ?? 'OTP request failed';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Updates the user's password using a verified OTP.
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
      final body = _ensureMap(result.data);
      final message = body['message']?.toString() ?? 'Password change failed';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Synchronizes [user] data with persistent local storage.
  /// 
  /// Updates both [CacheHelper] (Secure Storage) and [CachedVariables] (In-Memory).
  static Future<void> cacheData(UserModel? user) async {
    if (user != null) {
      if (user.id != null) {
        await CacheHelper.setData(key: CachedKeys.userId, value: user.id.toString());
        CachedVariables.userId = user.id;
      }
      if (user.name != null) {
        await CacheHelper.setData(key: CachedKeys.userName, value: user.name!);
        CachedVariables.userName = user.name;
      }
      if (user.phone_number != null) {
        await CacheHelper.setData(key: CachedKeys.phone_number, value: user.phone_number!);
        CachedVariables.phone_number = user.phone_number;
      }
      if (user.password != null) {
        await CacheHelper.setData(key: CachedKeys.password, value: user.password!);
        CachedVariables.password = user.password;
      }
    }
  }

  /// Hydrates [CachedVariables] from [CacheHelper] during app initialization.
  /// 
  /// Also handles legacy token migration from early app versions.
  static Future<void> getLocalDetails() async {
    CachedVariables.userId = int.tryParse(await CacheHelper.getData(key: CachedKeys.userId) ?? '');
    CachedVariables.userName = await CacheHelper.getData(key: CachedKeys.userName);
    CachedVariables.phone_number = await CacheHelper.getData(key: CachedKeys.phone_number);
    CachedVariables.password = await CacheHelper.getData(key: CachedKeys.password);
    CachedVariables.onBoard = await CacheHelper.getData(key: CachedKeys.onBoard);
    CachedVariables.token = await CacheHelper.getData(key: CachedKeys.authToken);

    // Migration logic for old installs (fcmToken -> authToken)
    if (CachedVariables.token == null) {
      final legacyToken = await CacheHelper.getData(key: CachedKeys.fcmToken);
      if (legacyToken != null) {
        log('Migrating auth token from legacy fcmToken key');
        await CacheHelper.setData(key: CachedKeys.authToken, value: legacyToken);
        await CacheHelper.deleteData(key: CachedKeys.fcmToken);
        CachedVariables.token = legacyToken;
      }
    }
    
    final isGoogle = await CacheHelper.getData(key: CachedKeys.isGoogleSignIn);
    CachedVariables.isGoogleSignIn = isGoogle == 'true';
  }

  /// Wipes all user data from memory and local storage.
  /// 
  /// Typically called during logout or account deletion.
  static Future<void> clearLocalDetails() async {
    CachedVariables.token = null;
    CachedVariables.userId = null;
    CachedVariables.userName = null;
    CachedVariables.email = null;
    CachedVariables.phone_number = null;
    CachedVariables.password = null;
    CachedVariables.isGoogleSignIn = false;

    await CacheHelper.deleteData(key: CachedKeys.userId);
    await CacheHelper.deleteData(key: CachedKeys.userName);
    await CacheHelper.deleteData(key: CachedKeys.phone_number);
    await CacheHelper.deleteData(key: CachedKeys.password);
    await CacheHelper.deleteData(key: CachedKeys.onBoard);
    await CacheHelper.deleteData(key: CachedKeys.authToken);
    await CacheHelper.deleteData(key: CachedKeys.isGoogleSignIn);
  }
}

/// Custom exception for authentication-related failures.
/// 
/// Contains a descriptive [message] and an optional HTTP error [code].
class AuthException implements Exception {
  final String message;
  final int? code;

  AuthException(this.message, this.code);

  @override
  String toString() {
    return message + (code != null ? ' (error: $code)' : '');
  }
}

