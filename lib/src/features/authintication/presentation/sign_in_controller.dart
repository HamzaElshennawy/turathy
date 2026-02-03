// import 'package:aldawly_mobile/src/features/authintication/data/auth_repository.dart';
// import 'package:aldawly_mobile/src/features/authintication/domain/user_model.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
//
// class SignInController extends StateNotifier<AsyncValue<void>> {
//   AuthRepository authRepository;
//   SignInController(this.authRepository)
//       : super(const AsyncValue<UserModel?>.data(null));
//
//   Future<bool> signInWithEmailAndPassword(String email, String password) async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(
//         () => authRepository.signInWithEmailAndPassword(email, password));
//     return state.hasError == false;
//   }
// }
//
// final signInControllerProvider =
//     StateNotifierProvider.autoDispose<SignInController, AsyncValue<void>>(
//         (ref) => SignInController(
//               ref.watch(authRepositoryProvider),
//             ));
