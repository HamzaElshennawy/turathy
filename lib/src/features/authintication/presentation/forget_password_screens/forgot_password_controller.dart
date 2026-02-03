import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_functions/app_functions.dart';
import '../../data/auth_repository.dart';

class ForgotPasswordController extends StateNotifier<AsyncValue<void>> {
  ForgotPasswordController() : super(const AsyncValue.data(null));

  Future<bool> requestOtp({required String e164Phone}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
        () => AuthRepository.requestOtp(number: e164Phone));
    if (result.hasError) {
      AppFunctions.logPrint(
          message: 'requestOtp error: ${result.error} ${result.stackTrace}');
      state = AsyncValue.error(
          result.error.toString(), result.stackTrace ?? StackTrace.empty);
      return false;
    }
    state = const AsyncValue.data(null);
    return result.value ?? false;
  }

  Future<bool> changePassword(
      {required String e164Phone,
      required String otp,
      required String password}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => AuthRepository.changePassword(
          number: e164Phone,
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

final forgotPasswordControllerProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordController,
    AsyncValue<void>>((ref) => ForgotPasswordController());
