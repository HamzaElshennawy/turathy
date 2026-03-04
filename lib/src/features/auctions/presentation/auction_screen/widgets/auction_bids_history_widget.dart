import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';

import 'package:turathy/src/core/helper/cache/cached_variables.dart';

class AuctionBidsHistoryWidget extends ConsumerWidget {
  final List<AuctionBid> initialBids;
  final int? productId;

  const AuctionBidsHistoryWidget({
    super.key,
    required this.initialBids,
    this.productId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for ALL accumulated socket bids (not just the latest one)
    final socketBids = ref.watch(accumulatedBidsProvider);

    // Filter socket bids by productId if provided
    final filteredSocketBids = socketBids
        .where((b) => productId == null || b.productId == productId)
        .toList();

    // Filter initial bids by productId
    final filteredInitialBids = initialBids
        .where((b) => productId == null || b.productId == productId)
        .toList();

    // Collect IDs from socket bids so we can deduplicate
    final socketBidIds = <int>{};
    for (final b in filteredSocketBids) {
      if (b.id != null) socketBidIds.add(b.id!);
    }

    // Combine: socket bids first (newest on top), then initial bids not already in socket list
    final allBidsRaw = <AuctionBid>[
      ...filteredSocketBids,
      ...filteredInitialBids.where(
        (b) => b.id == null || !socketBidIds.contains(b.id),
      ),
    ];

    // Hide inactive bids from other users — only the current user sees their own inactive bids
    final currentUserId = CachedVariables.userId;
    final allBids = allBidsRaw.where((b) {
      if (b.isActive == false) {
        // Only show inactive bids that belong to the current user
        return b.userId == currentUserId;
      }
      return true;
    }).toList();

    if (allBids.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'noBidsYet'.tr(),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    // Determine the overall highest active bid across ALL users
    final activeBids = allBidsRaw.where((b) => b.isActive == true).toList();
    AuctionBid? overallHighestActive;
    if (activeBids.isNotEmpty) {
      activeBids.sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0));
      overallHighestActive = activeBids.first;
    }
    final bool isCurrentUserOverallHighest =
        overallHighestActive != null &&
        overallHighestActive.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'bidHistory'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          gapH12,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allBids.length > 10
                ? 10
                : allBids.length, // Show last 10 bids
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final bid = allBids[index];
              final isMyBid =
                  currentUserId != null && bid.userId == currentUserId;

              // Green highlight: only when this is the user's highest active bid
              // AND the user is the overall highest active bidder
              bool showHighlight = false;
              if (isMyBid &&
                  bid.isActive == true &&
                  isCurrentUserOverallHighest) {
                final hasHigherActiveBid = allBids.any(
                  (b) =>
                      b.userId == currentUserId &&
                      b.isActive == true &&
                      (b.bid ?? 0) > (bid.bid ?? 0),
                );
                showHighlight = !hasHigherActiveBid;
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: showHighlight
                    ? BoxDecoration(
                        color: Colors.green.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: showHighlight
                            ? const Color(0xFF2D4739)
                            : Colors.grey[300],
                        child: Text(
                          (bid.user?.name ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: showHighlight
                                ? Colors.white
                                : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      gapW12,
                      // Bidder name and time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bid.user?.displayTitle ?? 'anonymous'.tr(),
                              style: TextStyle(
                                fontWeight: showHighlight
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (bid.createdAt != null)
                              Text(
                                _formatTime(bid.createdAt!),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Bid amount
                      Row(
                        children: [
                          Text(
                            '${bid.bid?.toStringAsFixed(0) ?? '0'} ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: showHighlight
                                  ? const Color(0xFF2D4739)
                                  : Colors.black87,
                            ),
                          ),
                          SvgPicture.asset(
                            'assets/icons/RSA.svg',
                            height: 12,
                            colorFilter: ColorFilter.mode(
                              showHighlight
                                  ? const Color(0xFF2D4739)
                                  : Colors.black87,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                      if (showHighlight) ...[
                        gapW8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D4739),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'highest'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(String createdAt) {
    try {
      final date = DateTime.parse(createdAt).toLocal();
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }
}
