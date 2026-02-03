import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_functions/app_functions.dart';
import '../data/auth_repository.dart';

class OtpController extends StateNotifier<AsyncValue<void>> {
  final TextEditingController otpController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  OtpController() : super(const AsyncValue.data(null));

  Future<bool> verifyOtp({required String phoneNumber}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => AuthRepository.verifyOtp(
          number: phoneNumber,
          otp: otpController.text.trim(),
        ));
    if (result.hasError) {
      AppFunctions.logPrint(
          message: 'verifyOtp error: ${result.error} ${result.stackTrace}');
      state = AsyncValue.error(
          result.error.toString(), result.stackTrace ?? StackTrace.empty);
      return false;
    }
    state = const AsyncValue.data(null);
    return result.value ?? false;
  }

  Future<bool> resendOtp({required String phoneNumber}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
        () => AuthRepository.resendOtp(number: phoneNumber));
    if (result.hasError) {
      AppFunctions.logPrint(
          message: 'resendOtp error: ${result.error} ${result.stackTrace}');
      state = AsyncValue.error(
          result.error.toString(), result.stackTrace ?? StackTrace.empty);
      return false;
    }
    state = const AsyncValue.data(null);
    return result.value ?? false;
  }
}

final otpControllerProvider =
    StateNotifierProvider.autoDispose<OtpController, AsyncValue<void>>(
        (ref) => OtpController());
