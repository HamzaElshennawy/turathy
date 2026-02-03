// import 'dart:async';
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// class ProfileScreenUserDetailsController
//     extends StateNotifier<AsyncValue<void>> {
//   ProfileScreenUserDetailsController({required this.authRepository})
//       : super(const AsyncValue<void>.data(null));
//   final AuthRepository authRepository;
//
//   Future<bool> signOut() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() => authRepository.signOut());
//     return state.hasError == false;
//   }
//
//   Future<bool> getUserDetails() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() => authRepository.getUserDetails());
//     return state.hasError == false;
//   }
// }
//
// final profileScreenControllerProvider = StateNotifierProvider.autoDispose<
//         ProfileScreenUserDetailsController, AsyncValue<void>>(
//     (ref) => ProfileScreenUserDetailsController(
//           authRepository: ref.watch(authRepositoryProvider),
//         ));
