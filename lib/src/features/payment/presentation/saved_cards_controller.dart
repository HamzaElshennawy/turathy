import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authintication/presentation/auth_controller.dart';
import '../../orders/data/payments_repository.dart';
import '../../orders/domain/saved_payment_method_model.dart';

final savedCardsControllerProvider = StateNotifierProvider<SavedCardsController, AsyncValue<List<SavedPaymentMethodModel>>>((ref) {
  return SavedCardsController(
    ref.watch(paymentsRepositoryProvider),
    ref.read(authControllerProvider.notifier).currentUser?.id,
  );
});

class SavedCardsController extends StateNotifier<AsyncValue<List<SavedPaymentMethodModel>>> {
  final PaymentsRepository _repository;
  final int? _userId;

  SavedCardsController(this._repository, this._userId) : super(const AsyncValue.loading()) {
    fetchCards();
  }

  Future<void> fetchCards() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final cards = await _repository.listSavedPaymentMethods(userId: _userId);
      state = AsyncValue.data(cards);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setDefaultCard(int methodId) async {
    if (_userId == null) return;
    try {
      await _repository.setDefaultSavedPaymentMethod(userId: _userId, methodId: methodId);
      await fetchCards();
    } catch (e) {
      // Handle error (could rethrow or let UI handle it)
      rethrow;
    }
  }

  Future<void> deleteCard(int methodId) async {
    if (_userId == null) return;
    try {
      await _repository.deactivateSavedPaymentMethod(userId: _userId, methodId: methodId);
      await fetchCards();
    } catch (e) {
      rethrow;
    }
  }
}
