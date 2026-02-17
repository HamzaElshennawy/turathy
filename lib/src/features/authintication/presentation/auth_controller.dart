import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_functions/app_functions.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/fcm/fcm_service.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final TextEditingController passwordController = TextEditingController(
    text: CachedVariables.password,
  );
  final nameController = TextEditingController();
  final phoneController = TextEditingController(
    text: CachedVariables.phone_number,
  );
  final formKey = GlobalKey<FormState>();

  AuthController() : super(const AsyncValue.data(null));

  bool isGoogleSignInProcessing = false;

  UserModel? get currentUser => state.value;

  Future<void> signIn(String fullphone_number, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => AuthRepository.signIn(fullphone_number, password),
    );

    if (state.hasValue && !state.hasError) {
      await FCMService().registerAfterLogin();
    }
  }

  // get user
  // Future<void> getUserDetails() async {
  //   state = const AsyncValue.loading();
  //   state = await AsyncValue.guard(() => AuthRepository.getUser());
  //   if (state.hasError) {
  //     AppFunctions.logPrint(message: 'getUserDetails ${state.error}');
  //   }
  // }

  Future<bool> signUp(String fullphone_number) async {
    state = const AsyncValue.loading();
    if (formKey.currentState!.validate()) {
      var user = UserModel(
        password: passwordController.text,
        name: nameController.text,
        phone_number: fullphone_number,
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

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    isGoogleSignInProcessing = true; // Set flag to true
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        state = const AsyncValue.data(null);
        isGoogleSignInProcessing = false; // Reset flag
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        state = AsyncValue.error(
          'Failed to get Google ID Token',
          StackTrace.empty,
        );
        isGoogleSignInProcessing = false; // Reset flag
        return;
      }

      state = await AsyncValue.guard(
        () => AuthRepository.googleSignIn(idToken),
      );

      if (state.hasValue && !state.hasError) {
        await FCMService().registerAfterLogin();
        // Navigation is handled by the UI listener based on the flag
      } else {
        isGoogleSignInProcessing = false; // Reset flag if error
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      isGoogleSignInProcessing = false; // Reset flag
    }
  }
}

// provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
      return AuthController();
    });
