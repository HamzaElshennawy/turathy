import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/fcm/fcm_service.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import 'country_code_provider.dart';

/// Known dial codes for the countries we support, longest first for matching.
const _knownDialCodes = [
  '+966', '+971', '+965', '+974', '+973', '+968', '+962', '+961', '+963',
  '+964', '+970', '+967', '+249', '+218', '+216', '+213', '+212', '+222',
  '+252', '+253', '+269', '+20',
];

/// Splits a phone number string into its dial code and local number.
/// Matches against known dial codes (longest first) to avoid greedy regex issues.
({String? dialCode, String? localNumber}) _splitPhoneNumber(String? phone) {
  if (phone == null || phone.isEmpty) return (dialCode: null, localNumber: phone);
  if (phone.startsWith('+')) {
    for (final code in _knownDialCodes) {
      if (phone.startsWith(code)) {
        return (
          dialCode: code,
          localNumber: phone.substring(code.length),
        );
      }
    }
    // Fallback: try generic 1-3 digit match
    final match = RegExp(r'^\+(\d{1,3})').firstMatch(phone);
    if (match != null) {
      return (
        dialCode: '+${match.group(1)!}',
        localNumber: phone.substring(match.group(0)!.length),
      );
    }
  }
  return (dialCode: null, localNumber: phone);
}

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;
  final TextEditingController passwordController = TextEditingController(
    text: CachedVariables.password,
  );
  final nameController = TextEditingController();
  late final TextEditingController phoneController;
  final formKey = GlobalKey<FormState>();

  AuthController(this.ref) : super(const AsyncValue.data(null)) {
    final parts = _splitPhoneNumber(CachedVariables.phone_number);
    phoneController = TextEditingController(text: parts.localNumber);
    if (parts.dialCode != null) {
      // Defer to avoid modifying another provider during initialization
      Future.microtask(() {
        ref.read(countryCodeProvider.notifier).setCountryCode(parts.dialCode!);
      });
    }
  }

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
      ref.invalidate(notificationsNotifierProvider);
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
        return {'status': 'error', 'message': e.toString()};
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
    ref.invalidate(notificationsNotifierProvider);
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
        ref.invalidate(notificationsNotifierProvider);
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
      return AuthController(ref);
    });
