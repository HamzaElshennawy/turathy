/// {@category Components}
///
/// A compact, horizontal-orientation card for displaying [AuctionModel] summaries.
/// 
/// Optimized for lists and search results where vertical space is premium,
/// this widget provides:
/// - **Spatial Efficiency**: A side-by-side layout (Thumbnail | Meta-information).
/// - **Real-time Lifecycle tracking**: An internal ticker for updating countdown timers.
/// - **Phase-Aware UI**: Adapts pricing and time labels based on whether the auction
///   is upcoming, active, or archived.
/// - **Core Interaction**: Direct navigation to [AuctionScreen] and wishlist support.
library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/sign_in_screen.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';

import '../../features/auctions/domain/auction_model.dart';
import '../../features/auctions/presentation/auction_screen/auction_screen.dart';
import '../constants/app_strings/app_strings.dart';

/// A landscape-oriented preview card for auction entities.
class HorizontalAuctionCard extends ConsumerStatefulWidget {
  /// The auction entity to display.
  /// 
  /// Note: The parameter name is legacy `product` but expects an [AuctionModel].
  final AuctionModel product;

  /// Creates a [HorizontalAuctionCard] for the given [product].
  const HorizontalAuctionCard({super.key, required this.product});

  @override
  ConsumerState<HorizontalAuctionCard> createState() =>
      _HorizontalAuctionCardState();
}

class _HorizontalAuctionCardState extends ConsumerState<HorizontalAuctionCard> {
  /// Periodic timer driven by the system clock to update time-sensitive UI fields.
  Timer? _timer;

  /// Cached snapshot of the delta between 'now' and auction completion.
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    
    // Heartbeat for live expiry countdowns (1Hz resolution).
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Refreshes the local [_remainingTime] duration.
  /// 
  /// Only executes if the auction model contains a valid `expiryDate`.
  void _calculateRemainingTime() {
    if (widget.product.expiryDate != null) {
      final expiryDate = widget.product.expiryDate!;
      final now = DateTime.now();
      setState(() {
        _remainingTime = expiryDate.isAfter(now) 
            ? expiryDate.difference(now) 
            : Duration.zero;
      });
    }
  }

  /// Converts a [Duration] into a standardized 'HH:MM:SS' string.
  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Reactive binding to wishlist/favorites state
    final favoritesState = ref.watch(favoritesControllerProvider);
    final isLiked = favoritesState.maybeWhen(
      data: (state) => state.likedAuctionIds.contains(widget.product.id),
      orElse: () => false,
    );

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Standard navigation to auction details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionScreen(widget.product),
            ),
          );
        },
        child: Row(
          children: [
            // ── Primary Media Section ───────────────────────────────────────
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.imageUrl ?? '',
                      memCacheHeight: 400,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 50),
                      ),
                    ),
                  ),
                  // Top-Left Floating Action: Favorite
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildHeartIcon(isLiked),
                  ),
                ],
              ),
            ),
            
            // ── Content & Metadata Section ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTextContent(),
                    _buildMetadataLayer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Internal: Builds the favoriting toggle with session guard.
  Widget _buildHeartIcon(bool isLiked) {
    return InkWell(
      onTap: () {
        final user = ref.read(authControllerProvider).value;
        if (user == null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen()));
          return;
        }
        ref.read(favoritesControllerProvider.notifier).toggleLikeAuction(widget.product);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  /// Internal: Renders localized text data with strict overflow constraints.
  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.localizedTitle(context.locale.languageCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.product.localizedDescription(context.locale.languageCode),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.3,
          ),
        ),
      ],
    );
  }

  /// Internal: Renders the pricing and lifecycle metadata (Time/Status).
  Widget _buildMetadataLayer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.product.minBidPrice ?? 0} ${AppStrings.currency.tr()}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        // Dynamic time indicator based on auction life stage
        if (widget.product.expiryDate != null &&
            widget.product.startDate != null)
          Builder(
            builder: (context) {
              final now = DateTime.now();
              final startDate = widget.product.startDate!;
              final expiryDate = widget.product.expiryDate!;

              if (startDate.isAfter(now)) {
                // Incoming Auction Date
                return Text(
                  '${AppStrings.startedAt.tr()}: ${DateFormat('MMM d').format(startDate)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1B5E20),
                  ),
                );
              } else if (expiryDate.isBefore(now)) {
                // Archived Auction Date
                return Text(
                  '${AppStrings.endedOn.tr()}: ${DateFormat('MMM d').format(expiryDate)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                );
              } else {
                // Live Countdown Ticker
                return Row(
                  children: [
                    const Icon(Icons.timer, size: 14, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_remainingTime),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
      ],
    );
  }
}

