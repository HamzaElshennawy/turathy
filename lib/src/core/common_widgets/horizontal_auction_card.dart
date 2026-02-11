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

class HorizontalAuctionCard extends ConsumerStatefulWidget {
  final AuctionModel product;

  const HorizontalAuctionCard({super.key, required this.product});

  @override
  ConsumerState<HorizontalAuctionCard> createState() =>
      _HorizontalAuctionCardState();
}

class _HorizontalAuctionCardState extends ConsumerState<HorizontalAuctionCard> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    if (widget.product.expiryDate != null) {
      final expiryDate = widget.product.expiryDate!;
      final now = DateTime.now();
      if (expiryDate.isAfter(now)) {
        setState(() {
          _remainingTime = expiryDate.difference(now);
        });
      } else {
        setState(() {
          _remainingTime = Duration.zero;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesControllerProvider);
    final isLiked = favoritesState.maybeWhen(
      data: (state) => state.likedAuctionIds.contains(widget.product.id),
      orElse: () => false,
    );

    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionScreen(widget.product),
            ),
          );
        },
        child: Row(
          children: [
            // Image Section
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
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 50),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: InkWell(
                      onTap: () {
                        final user = ref.read(authControllerProvider).value;
                        if (user == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInScreen(),
                            ),
                          );
                          return;
                        }
                        ref
                            .read(favoritesControllerProvider.notifier)
                            .toggleLikeAuction(widget.product);
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
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title ?? '',
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
                          widget.product.description ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.product.minBidPrice ?? 0} ${AppStrings.currency.tr()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        // Time Display
                        if (widget.product.expiryDate != null &&
                            widget.product.startDate != null)
                          Builder(
                            builder: (context) {
                              final now = DateTime.now();
                              final startDate = widget.product.startDate!;
                              final expiryDate = widget.product.expiryDate!;

                              if (startDate.isAfter(now)) {
                                return Text(
                                  '${AppStrings.startedAt.tr()}: ${DateFormat('MMM d').format(startDate)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1B5E20),
                                  ),
                                );
                              } else if (expiryDate.isBefore(now)) {
                                return Text(
                                  '${AppStrings.endedOn.tr()}: ${DateFormat('MMM d').format(expiryDate)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                );
                              } else {
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      size: 14,
                                      color: Color(0xFFD32F2F),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(_remainingTime),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFD32F2F), // Red color
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
