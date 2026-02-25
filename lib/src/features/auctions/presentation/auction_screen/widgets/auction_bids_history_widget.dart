import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
    // Watch for new bids from the socket
    final newBid = ref.watch(currentBidStateProvider);

    // Combine initial bids with new bids (new bids on top)
    // Filter by productId if provided
    final allBids = <AuctionBid>[
      if (newBid != null &&
          (productId == null || newBid.productId == productId))
        newBid,
      ...initialBids.where(
        (b) => productId == null || b.productId == productId,
      ),
    ];

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
              final isLatest = index == 0;
              final isMyBid =
                  CachedVariables.userId != null &&
                  bid.userId == CachedVariables.userId;
              final showHighlight = isLatest && isMyBid;

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
                      Text(
                        '\$${bid.bid?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: showHighlight
                              ? const Color(0xFF2D4739)
                              : Colors.black87,
                        ),
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
