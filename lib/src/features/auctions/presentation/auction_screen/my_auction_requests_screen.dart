import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/auction_screen.dart';

import '../../../../core/constants/app_strings/app_strings.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/auctions_repository.dart';
import '../../domain/auction_access_model.dart';
import 'live_auction_screen.dart';

final myAuctionRequestsProvider =
    StreamProvider.autoDispose<List<AuctionAccessModel>>((ref) async* {
      final repository = ref.watch(productsRepositoryProvider);
      while (true) {
        try {
          final requests = await repository.getUserRequests();
          yield requests;
        } catch (e) {
          debugPrint("Error fetching auction requests: $e");
        }
        await Future.delayed(const Duration(seconds: 15));
      }
    });

class MyAuctionRequestsScreen extends ConsumerWidget {
  const MyAuctionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsValue = ref.watch(myAuctionRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppStrings.myAuctionRequests.tr()),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: requestsValue.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Text(
                AppStrings.noRequestsFound.tr(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myAuctionRequestsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (context, index) => gapH16,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _RequestCardWidget(request: request);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              gapH16,
              Text(error.toString(), textAlign: TextAlign.center),
              gapH16,
              ElevatedButton(
                onPressed: () => ref.invalidate(myAuctionRequestsProvider),
                child: Text(AppStrings.retry.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCardWidget extends StatelessWidget {
  final AuctionAccessModel request;

  const _RequestCardWidget({required this.request});

  @override
  Widget build(BuildContext context) {
    Color getStatusColor(String status) {
      switch (status.toUpperCase()) {
        case 'APPROVED':
          return Colors.green;
        case 'DENIED':
        case 'BLOCKED':
          return Colors.red;
        case 'PENDING':
        default:
          return Colors.orange;
      }
    }

    String getStatusText(String status) {
      switch (status.toUpperCase()) {
        case 'APPROVED':
          return AppStrings.accessGranted.tr();
        case 'DENIED':
        case 'BLOCKED':
          return AppStrings.accessDenied.tr();
        case 'PENDING':
        default:
          return AppStrings.accessPending.tr();
      }
    }

    final isGranted = request.status.toUpperCase() == 'APPROVED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isGranted
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AuctionScreen(request.auction!),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Request Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: getStatusColor(
                      request.status,
                    ).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGranted
                        ? Icons.check_circle_outline
                        : Icons.pending_actions,
                    color: getStatusColor(request.status),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Request Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.auction?.localizedTitle(
                              context.locale.languageCode,
                            ) ??
                            '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(request.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(
                      request.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: getStatusColor(
                        request.status,
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    getStatusText(request.status),
                    style: TextStyle(
                      color: getStatusColor(request.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
