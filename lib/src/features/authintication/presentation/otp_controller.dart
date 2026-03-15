import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_functions/app_functions.dart';
import 'auth_controller.dart';
import '../data/auth_repository.dart';

class OtpController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final TextEditingController otpController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  OtpController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> verifyOtp({required String phone_number}) async {
    state = const AsyncValue.loading();
    try {
      final user = await AuthRepository.verifyOtp(
        number: phone_number,
        otp: otpController.text.trim(),
      );
      
      // Update global auth state
      ref.read(authControllerProvider.notifier).updateUser(user);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      AppFunctions.logPrint(
        message: 'verifyOtp error: $e $st',
      );
      state = AsyncValue.error(
        e.toString(),
        st,
      );
      return false;
    }
  }

  Future<bool> resendOtp({required String phone_number}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => AuthRepository.resendOtp(number: phone_number),
    );
    if (result.hasError) {
      AppFunctions.logPrint(
        message: 'resendOtp error: ${result.error} ${result.stackTrace}',
      );
      state = AsyncValue.error(
        result.error.toString(),
        result.stackTrace ?? StackTrace.empty,
      );
      return false;
    }
    state = const AsyncValue.data(null);
    return result.value ?? false;
  }
}

final otpControllerProvider =
    StateNotifierProvider.autoDispose<OtpController, AsyncValue<void>>(
      (ref) => OtpController(ref),
    );
