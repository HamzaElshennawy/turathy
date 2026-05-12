import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:turathy/src/core/constants/app_functions/app_functions.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/payment/presentation/widgets/payment_card_widget.dart';
import 'package:turathy/src/features/payment/presentation/saved_cards_controller.dart';
import 'package:turathy/src/features/orders/data/payments_repository.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedCardsScreen extends ConsumerWidget {
  const SavedCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedCardsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.savedCards.tr()),
        centerTitle: true,
      ),
      body: state.when(
        data: (cards) {
          if (cards.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(savedCardsControllerProvider.notifier)
                  .fetchCards();
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return PaymentCardWidget(
                  card: card,
                  onSetDefault: () {
                    ref
                        .read(savedCardsControllerProvider.notifier)
                        .setDefaultCard(card.id);
                  },
                  onDelete: () {
                    _confirmDelete(context, ref, card.id);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.couldNotLoadSavedCards.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(savedCardsControllerProvider.notifier).fetchCards();
                },
                child: Text(AppStrings.retry.tr()),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewCard(context, ref),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addCard.tr()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.credit_card_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppStrings.noSavedPaymentMethods.tr(),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.removeCard.tr()),
        content: Text(
          "Are you sure you want to delete this card?",
        ), // Use AppStrings if available
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.delete.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      ref.read(savedCardsControllerProvider.notifier).deleteCard(id);
    }
  }

  Future<void> _addNewCard(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final session = await ref
          .read(paymentsRepositoryProvider)
          .createGeideaSaveCardSession(language: context.locale.languageCode);
      if (context.mounted) {
        Navigator.pop(context); // close loader
      }

      final url = Uri.parse(
        '${EndPoints.baseUrl}/api/payments/geidea/save-card/redirect?sessionId=${session.sessionId}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
        // Refresh cards when they come back
        ref.read(savedCardsControllerProvider.notifier).fetchCards();
      } else {
        if (context.mounted) {
          AppFunctions.showSnackBar(
            context: context,
            message: AppStrings.couldNotStartPayment.tr(),
            isError: true,
            icon: Icons.error,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loader
        AppFunctions.showSnackBar(
          context: context,
          message: AppStrings.couldNotStartPayment.tr(),
          isError: true,
          icon: Icons.error,
        );
      }
    }
  }
}
