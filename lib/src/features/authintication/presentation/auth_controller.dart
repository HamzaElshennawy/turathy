/// {@category Presentation}
///
/// Business logic and state management for application-wide authentication.
/// 
/// This controller manages the [UserModel] state using Riverpod's [StateNotifier].
/// It also handles form logic for sign-in/up and coordinates side-effects like 
/// Firebase Cloud Messaging (FCM) token registration.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/fcm/fcm_service.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import 'country_code_provider.dart';

/// Known dial codes for supported countries, ordered by length (longest first)
/// to ensure greedy matching in [_splitPhoneNumber].
const _knownDialCodes = [
  '+966', '+971', '+965', '+974', '+973', '+968', '+962', '+961', '+963',
  '+964', '+970', '+967', '+249', '+218', '+216', '+213', '+212', '+222',
  '+252', '+253', '+269', '+20',
];

/// Deconstructs a raw phone string into its dial code and local component.
/// 
/// Uses [_knownDialCodes] for prioritized matching.
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
    // Generic fallback for unknown codes.
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

/// Manages the current user state and authentication operations.
class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;

  /// Controllers for managing persistent form state across auth screens.
  final TextEditingController passwordController = TextEditingController(
    text: CachedVariables.password,
  );
  final nameController = TextEditingController();
  late final TextEditingController phoneController;

  /// Root form key for validation in signup/login flows.
  final formKey = GlobalKey<FormState>();

  AuthController(this.ref) : super(const AsyncValue.data(null)) {
    // Restore phone component and dial code from cache on init.
    final parts = _splitPhoneNumber(CachedVariables.phone_number);
    phoneController = TextEditingController(text: parts.localNumber);
    if (parts.dialCode != null) {
      Future.microtask(() {
        ref.read(countryCodeProvider.notifier).setCountryCode(parts.dialCode!);
      });
    }
  }

  /// Indicates if a Google Sign-In process is currently active.
  bool isGoogleSignInProcessing = false;

  /// Shortcut to the currently authenticated user (null if guest).
  UserModel? get currentUser => state.value;

  /// Forces a state update for the user (e.g., after profile completion).
  void updateUser(UserModel user) {
    state = AsyncValue.data(user);
  }

  /// Performs credential-based login.
  /// 
  /// Triggers [FCMService] registration and clears notification state on success.
  Future<Map<String, dynamic>> signIn(
    String fullphone_number,
    String password,
  ) async {
    state = const AsyncValue.loading();
    try {
      final result = await AuthRepository.signIn(fullphone_number, password);
      final user = result['user'] as UserModel;
      state = AsyncValue.data(user);
      
      // Post-login side effects
      await FCMService().registerAfterLogin();
      ref.invalidate(notificationsNotifierProvider);
      
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Triggers the account creation flow.
  /// 
  /// Validates the [formKey] before calling the repository.
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

  /// Wipes the local session and invalidates relevant providers.
  Future<bool> signOut() async {
    state = const AsyncValue.loading();
    await AuthRepository.clearLocalDetails();
    state = const AsyncValue.data(null);
    ref.invalidate(notificationsNotifierProvider);
    return true;
  }

  /// Initiates the Google Sign-In OAuth flow.
  /// 
  /// On success, sends the ID token to the backend for verification.
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    isGoogleSignInProcessing = true;
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        state = const AsyncValue.data(null);
        isGoogleSignInProcessing = false;
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        state = AsyncValue.error(
          'Failed to get Google ID Token',
          StackTrace.empty,
        );
        isGoogleSignInProcessing = false;
        return;
      }

      state = await AsyncValue.guard(
        () => AuthRepository.googleSignIn(idToken),
      );

      if (state.hasValue && !state.hasError) {
        await FCMService().registerAfterLogin();
        ref.invalidate(notificationsNotifierProvider);
      } else {
        isGoogleSignInProcessing = false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      isGoogleSignInProcessing = false;
    }
  }
}

/// Global provider for the [AuthController].
/// 
/// Monitors the authentication state across the entire application.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
      return AuthController(ref);
    });

