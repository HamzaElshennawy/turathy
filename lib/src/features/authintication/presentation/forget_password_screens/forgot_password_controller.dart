/// {@category Presentation}
///
/// Controller for managing the password recovery/reset process.
/// 
/// This controller handles requesting an OTP for a given phone number and
/// subsequently verifying that OTP to set a new password.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_functions/app_functions.dart';
import '../../data/auth_repository.dart';

/// State notifier for the forgot password flow.
/// 
/// It uses [AsyncValue] to track the status of the network requests,
/// allowing the UI to show loading indicators or error messages.
class ForgotPasswordController extends StateNotifier<AsyncValue<void>> {
  ForgotPasswordController() : super(const AsyncValue.data(null));

  /// Requests a password reset OTP for the specified phone number.
  /// 
  /// The [e164Phone] must be in international format (e.g., +9665XXXXXXXX).
  /// Returns a challenge token if the request was successful.
  Future<String?> requestOtp({required String e164Phone}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
        () => AuthRepository.requestOtp(number: e164Phone));
    
    if (result.hasError) {
      AppFunctions.logPrint(
          message: 'requestOtp error: ${result.error} ${result.stackTrace}');
      state = AsyncValue.error(
          result.error.toString(), result.stackTrace ?? StackTrace.empty);
      return null;
    }
    
    state = const AsyncValue.data(null);
    return result.value?['challengeToken'] as String?;
  }

  /// Verifies the [otp] and resets the user's password to [password].
  /// 
  /// Requires the [e164Phone] associated with the account.
  /// Returns `true` if the password was updated successfully.
  Future<bool> changePassword(
      {required String challengeToken,
      required String otp,
      required String password}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => AuthRepository.changePassword(
          challengeToken: challengeToken,
          otp: otp,
          password: password,
        ));
    
    if (result.hasError) {
      AppFunctions.logPrint(
          message:
              'changePassword error: ${result.error} ${result.stackTrace}');
      state = AsyncValue.error(
          result.error.toString(), result.stackTrace ?? StackTrace.empty);
      return false;
    }
    
    state = const AsyncValue.data(null);
    return result.value ?? false;
  }
}

/// Provider for the [ForgotPasswordController], disposed automatically when unused.
final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController,
    AsyncValue<void>>((ref) => ForgotPasswordController());
