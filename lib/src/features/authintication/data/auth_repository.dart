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
import 'dart:io';

import 'package:dio/dio.dart';

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

String _currentPlatformLabel() {
  if (Platform.isAndroid) return 'ANDROID';
  if (Platform.isIOS) return 'IOS';
  return 'UNKNOWN';
}

Map<String, dynamic> _extractAuthData(Map<String, dynamic> body) {
  return _ensureMap(body['data']);
}

Map<String, dynamic> _extractUserData(Map<String, dynamic> data) {
  final nestedUser = _ensureMap(data['user']);
  return nestedUser.isNotEmpty ? nestedUser : data;
}

String? _extractAccessToken(Map<String, dynamic> data) {
  final token = data['accessToken'] ?? data['token'];
  return token is String && token.isNotEmpty ? token : null;
}

String? _extractRefreshToken(Map<String, dynamic> data) {
  final token = data['refreshToken'];
  return token is String && token.isNotEmpty ? token : null;
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
      data: {
        'phone_number': phone,
        'password': password,
        'platform': _currentPlatformLabel(),
      },
    );
    final body = _ensureMap(result.data);
    
    if (result.statusCode == 200 || result.statusCode == 201) {
      final data = _extractAuthData(body);
      if (data['requiresOtp'] == true) {
        return {
          'status': body['status'] ?? 'success',
          'requiresOtp': true,
          'challengeToken': data['challengeToken'],
          'maskedDestination': data['maskedDestination'],
          'purpose': data['purpose'],
          'deliveryMethod': data['deliveryMethod'],
          'fallbackMethod': data['fallbackMethod'],
          'expiresIn': data['expiresIn'],
        };
      }
      final userData = _extractUserData(data);
      final user = UserModel.fromJson(userData);
      final token = _extractAccessToken(data);
      final refreshToken = _extractRefreshToken(data);
      if (token != null) {
        await CacheHelper.setData(key: CachedKeys.authToken, value: token);
        CachedVariables.token = token;
      }
      if (refreshToken != null) {
        await CacheHelper.setData(
          key: CachedKeys.refreshToken,
          value: refreshToken,
        );
        CachedVariables.refreshToken = refreshToken;
      }

      // Store credentials for auto-login on next app restart.
      await cacheData(user.copyWith(password: password, phone_number: phone));

      return {
        'user': user,
        'status': body['status'] ?? 'success',
        'isProfileComplete': userData['isProfileComplete'] ?? true,
        'missingFields': userData['missingFields'] ?? [],
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
      data: {
        'token': token,
        'platform': _currentPlatformLabel(),
      },
    );

    final body = _ensureMap(result.data);
    if (result.statusCode == 200 || result.statusCode == 201) {
      final data = _extractAuthData(body);
      final user = UserModel.fromJson(_extractUserData(data));
      final token = _extractAccessToken(data);
      final refreshToken = _extractRefreshToken(data);
      if (token != null) {
        await CacheHelper.setData(key: CachedKeys.authToken, value: token);
        CachedVariables.token = token;
      }
      if (refreshToken != null) {
        await CacheHelper.setData(
          key: CachedKeys.refreshToken,
          value: refreshToken,
        );
        CachedVariables.refreshToken = refreshToken;
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
        'requiresOtp': data['requiresOtp'] ?? true,
        'challengeToken': data['challengeToken'],
        'maskedDestination': data['maskedDestination'],
        'purpose': data['purpose'],
        'deliveryMethod': data['deliveryMethod'],
        'fallbackMethod': data['fallbackMethod'],
        'expiresIn': data['expiresIn'],
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
    required String challengeToken,
    required String otp,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.verifyOTP,
      data: {'challengeToken': challengeToken, 'otp': otp},
    );
    final body = _ensureMap(result.data);
    if (result.statusCode == 200 || result.statusCode == 201) {
      final data = _extractAuthData(body);
      final user = UserModel.fromJson(_extractUserData(data));
      final token = _extractAccessToken(data);
      final refreshToken = _extractRefreshToken(data);
      if (token != null) {
        await CacheHelper.setData(key: CachedKeys.authToken, value: token);
        CachedVariables.token = token;
      }
      if (refreshToken != null) {
        await CacheHelper.setData(
          key: CachedKeys.refreshToken,
          value: refreshToken,
        );
        CachedVariables.refreshToken = refreshToken;
      }

      await cacheData(user);
      return user;
    } else {
      final message = body['message']?.toString() ?? 'OTP verification failed';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Requests a new OTP code to be sent to the user's phone.
  static Future<Map<String, dynamic>> resendOtp({
    required String challengeToken,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.resendOTP,
      data: {'challengeToken': challengeToken},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      final body = _ensureMap(result.data);
      final data = _extractAuthData(body);
      return {
        'status': body['status'] ?? 'success',
        'challengeToken': data['challengeToken'],
        'maskedDestination': data['maskedDestination'],
        'purpose': data['purpose'],
        'deliveryMethod': data['deliveryMethod'],
        'fallbackMethod': data['fallbackMethod'],
        'expiresIn': data['expiresIn'],
      };
    } else {
      final body = _ensureMap(result.data);
      final message = body['message']?.toString() ?? 'OTP resend failed';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Triggers the OTP flow (e.g. for registration or password reset).
  static Future<Map<String, dynamic>> requestOtp({required String number}) async {
    final result = await DioHelper.postData(
      url: EndPoints.requestOTP,
      data: {'number': number},
    );
    if (result.statusCode == 200 || result.statusCode == 201) {
      final body = _ensureMap(result.data);
      final data = _extractAuthData(body);
      return {
        'status': body['status'] ?? 'success',
        'challengeToken': data['challengeToken'],
        'maskedDestination': data['maskedDestination'],
        'purpose': data['purpose'],
        'deliveryMethod': data['deliveryMethod'],
        'fallbackMethod': data['fallbackMethod'],
        'expiresIn': data['expiresIn'],
      };
    } else {
      final body = _ensureMap(result.data);
      final message = body['message']?.toString() ?? 'OTP request failed';
      throw AuthException(message, result.statusCode);
    }
  }

  /// Updates the user's password using a verified OTP.
  static Future<bool> changePassword({
    required String challengeToken,
    required String otp,
    required String password,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.changePassword,
      data: {
        'challengeToken': challengeToken,
        'otp': otp,
        'password': password,
      },
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
      if (user.profilePicUrl != null) {
        await CacheHelper.setData(key: CachedKeys.profilePicUrl, value: user.profilePicUrl!);
        CachedVariables.profilePicUrl = user.profilePicUrl;
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
    CachedVariables.profilePicUrl = await CacheHelper.getData(key: CachedKeys.profilePicUrl);
    CachedVariables.onBoard = await CacheHelper.getData(key: CachedKeys.onBoard);
    CachedVariables.token = await CacheHelper.getData(key: CachedKeys.authToken);
    CachedVariables.refreshToken =
        await CacheHelper.getData(key: CachedKeys.refreshToken);

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
    CachedVariables.refreshToken = null;
    CachedVariables.userId = null;
    CachedVariables.userName = null;
    CachedVariables.email = null;
    CachedVariables.phone_number = null;
    CachedVariables.password = null;
    CachedVariables.isGoogleSignIn = false;
    CachedVariables.profilePicUrl = null;

    await CacheHelper.deleteData(key: CachedKeys.userId);
    await CacheHelper.deleteData(key: CachedKeys.userName);
    await CacheHelper.deleteData(key: CachedKeys.phone_number);
    await CacheHelper.deleteData(key: CachedKeys.password);
    await CacheHelper.deleteData(key: CachedKeys.onBoard);
    await CacheHelper.deleteData(key: CachedKeys.authToken);
    await CacheHelper.deleteData(key: CachedKeys.refreshToken);
    await CacheHelper.deleteData(key: CachedKeys.isGoogleSignIn);
    await CacheHelper.deleteData(key: CachedKeys.profilePicUrl);
  }

  static Future<bool> refreshAccessToken() async {
    final refreshToken = CachedVariables.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final result = await DioHelper.postData(
      url: EndPoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    final body = _ensureMap(result.data);
    if (result.statusCode != 200 && result.statusCode != 201) {
      return false;
    }

    final data = _extractAuthData(body);
    final accessToken = _extractAccessToken(data);
    final rotatedRefreshToken = _extractRefreshToken(data);
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    await CacheHelper.setData(key: CachedKeys.authToken, value: accessToken);
    CachedVariables.token = accessToken;

    if (rotatedRefreshToken != null && rotatedRefreshToken.isNotEmpty) {
      await CacheHelper.setData(
        key: CachedKeys.refreshToken,
        value: rotatedRefreshToken,
      );
      CachedVariables.refreshToken = rotatedRefreshToken;
    }

    return true;
  }

  /// Uploads a new profile picture to the backend.
  ///
  /// Requires the [userId] and the local [filePath] of the selected image.
  /// Returns the network URL of the uploaded image.
  static Future<String> uploadProfilePicture({
    required int userId,
    required String filePath,
  }) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'picture': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final result = await DioHelper.putData(
      url: EndPoints.uploadProfilePicture(userId),
      data: formData,
      token: CachedVariables.token,
      isMultipart: true,
    );

    final body = _ensureMap(result.data);
    if (result.statusCode == 200 || result.statusCode == 201) {
      final data = _ensureMap(body['data']);
      final profilePicUrl = data['profilePicUrl'] as String;
      
      await CacheHelper.setData(key: CachedKeys.profilePicUrl, value: profilePicUrl);
      CachedVariables.profilePicUrl = profilePicUrl;
      
      return profilePicUrl;
    } else {
      final message = body['message']?.toString() ?? 'Failed to upload profile picture';
      throw AuthException(message, result.statusCode);
    }
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

String getFriendlyAuthMessage(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final rawMessage = error is AuthException
      ? error.message
      : error?.toString() ?? fallback;
  final message = rawMessage.trim();
  final normalized = message.toLowerCase();

  if (normalized.isEmpty) {
    return fallback;
  }
  if (normalized.contains('please enter a valid otp') ||
      normalized.contains('otp verification failed')) {
    return 'The verification code is incorrect. Please try again.';
  }
  if (normalized.contains('failed to send otp')) {
    return 'We could not send the verification code right now. Please try again.';
  }
  if (normalized.contains('failed to verify otp')) {
    return 'We could not verify the code right now. Please try again.';
  }
  if (normalized.contains('invalid credentials')) {
    return 'Incorrect phone number or password.';
  }
  if (normalized.contains('user not found')) {
    return 'We could not find an account with these details.';
  }
  if (normalized.contains('there is a user with this number already')) {
    return 'An account with this phone number already exists.';
  }
  if (normalized.contains('phone number is required')) {
    return 'Please enter your phone number.';
  }
  if (normalized.contains('this account does not support password login')) {
    return 'This account uses social sign-in. Please continue with Google or Apple.';
  }
  if (normalized.contains('provider is not configured')) {
    return 'Verification is temporarily unavailable. Please try again later.';
  }
  if (normalized.contains('password changed successfully')) {
    return 'Your password has been updated successfully.';
  }
  if (normalized.contains('something went wrong')) {
    return fallback;
  }

  return message;
}


