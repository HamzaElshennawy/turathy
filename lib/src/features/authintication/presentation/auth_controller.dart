import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_functions/app_functions.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final TextEditingController passwordController = TextEditingController(
    text: CachedVariables.password,
  );
  final nameController = TextEditingController();
  final phoneController = TextEditingController(
    text: CachedVariables.phoneNumber,
  );
  final formKey = GlobalKey<FormState>();

  AuthController() : super(const AsyncValue.data(null));

  UserModel? get currentUser => state.value;

  Future<void> signIn(String phone, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => AuthRepository.signIn(phone, password),
    );
  }

  // get user
  // Future<void> getUserDetails() async {
  //   state = const AsyncValue.loading();
  //   state = await AsyncValue.guard(() => AuthRepository.getUser());
  //   if (state.hasError) {
  //     AppFunctions.logPrint(message: 'getUserDetails ${state.error}');
  //   }
  // }

  Future<bool> signUp() async {
    state = const AsyncValue.loading();
    if (formKey.currentState!.validate()) {
      var user = UserModel(
        password: passwordController.text,
        name: nameController.text,
        //phoneNumber: '+966${phoneController.text}',
        phoneNumber: '12${phoneController.text}',
      );
      final result = await AsyncValue.guard(
        () => AuthRepository.createUser(user),
      );
      if (result.hasError) {
        AppFunctions.logPrint(
          message: '${result.error} error${result.stackTrace}',
        );
        state = AsyncValue.error(
          result.error.toString(),
          result.stackTrace ?? StackTrace.empty,
        );
        return false;
      } else if (result.hasValue) {
        state = const AsyncValue.data(null);
        return result.value ?? false;
      }
    }
    state = const AsyncValue.error('Please fill all fields', StackTrace.empty);
    return false;
  }

  Future<bool> signOut() async {
    state = const AsyncValue.loading();
    // final result = await AsyncValue.guard(() => AuthRepository.signOut());
    // if (result.hasError) {
    //   state = AsyncValue.error(result.error.toString(), StackTrace.empty);
    //   state = oldState;
    //   return false;
    // }
    await AuthRepository.clearLocalDetails();
    state = const AsyncValue.data(null);
    return true;
  }

  // delete user
  // Future<bool> deleteUser() async {
  //   final oldState = state;
  //   state = const AsyncValue.loading();
  //   final result = await AsyncValue.guard(() => AuthRepository.deleteAccount());
  //   if (result.hasError) {
  //     state = AsyncValue.error(result.error.toString(), StackTrace.empty);
  //     state = oldState;
  //     return false;
  //   }
  //   await AuthRepository.clearLocalDetails();
  //   state = const AsyncValue.data(null);
  //   return true;
  // }
}

// provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
      return AuthController();
    });
