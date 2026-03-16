import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  /// Update the user state directly (e.g. after profile edit)
  void updateUser(UserModel user) {
    state = AsyncValue.data(user);
  }

  Future<Map<String, dynamic>> signIn(
    String fullphone_number,
    String password,
  ) async {
    state = const AsyncValue.loading();
    try {
      final result = await AuthRepository.signIn(fullphone_number, password);
      final user = result['user'] as UserModel;
      state = AsyncValue.data(user);
      await FCMService().registerAfterLogin();
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Return an error map to prevent unhandled exceptions from crashing the app
      // when the caller (like SplashScreen) doesn't use a try/catch block.
      return {'status': 'error', 'message': e.toString()};
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

  Future<Map<String, dynamic>> signUp(String fullphone_number) async {
    state = const AsyncValue.loading();
    if (formKey.currentState!.validate()) {
      var user = UserModel(
        password: passwordController.text,
        name: nameController.text,
        phone_number: fullphone_number,
      );
      try {
        final result = await AuthRepository.createUser(user);
        state = const AsyncValue.data(null);
        return result;
      } catch (e, st) {
        state = AsyncValue.error(e.toString(), st);
        rethrow;
      }
    }
    const error = 'Please fill all fields';
    state = const AsyncValue.error(error, StackTrace.empty);
    return {'status': 'error', 'message': error};
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
