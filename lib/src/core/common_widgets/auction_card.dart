/// {@category Components}
///
/// A primary list-item component representing an [AuctionModel].
/// 
/// This widget coordinates multiple real-time and business logic layers:
/// - **Visual Representation**: Displays auction title, description, and high-resolution thumbnail with [Hero] support.
/// - **Real-time Countdowns**: Updates every second to show time remaining until 'Pre-auction' or 'Live' phases.
/// - **Access Control**: Validates user permission status (PENDING, GRANTED, DENIED) via [AuctionAccessService].
/// - **State Interactions**: Supports favoriting/liking auctions and launching fullscreen image previews.
/// - **Navigation Logic**: Context-aware routing to either [AuctionScreen] or [LiveAuctionScreen] based on phase.
library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/sign_in_screen.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';

import '../../features/auctions/data/auction_access_service.dart';
import '../../features/auctions/domain/auction_model.dart';
import '../../features/auctions/presentation/auction_screen/auction_screen.dart';
import '../../features/auctions/presentation/auction_screen/live_auction_screen.dart';
import '../constants/app_functions/app_functions.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings/app_strings.dart';
import '../helper/cache/cached_variables.dart';

/// A stateful, consumer-driven card for displaying auction previews.
class AuctionCard extends ConsumerStatefulWidget {
  /// The underlying data model for this auction instance.
  final AuctionModel auction;

  /// Optional identifier for [Hero] transition animations. 
  /// Defaults to [auction.id] if provided as an integer.
  final String? heroTag;

  /// Creates an [AuctionCard] with the required [auction] metadata.
  const AuctionCard({super.key, required this.auction, this.heroTag});

  @override
  ConsumerState<AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends ConsumerState<AuctionCard> {
  /// Periodic timer responsible for driving the countdown UI every second.
  Timer? _timer;

  /// Snapshot of time remaining until the high-intensity 'Live' phase begins.
  Duration _remainingTimeForLive = Duration.zero;

  /// Snapshot of time remaining until the 'Pre-auction' browsing phase begins.
  Duration _remainingTimeForPreAuction = Duration.zero;

  /// Result of the most recent access check from the server.
  /// Common values: 'GRANTED', 'PENDING', 'DENIED', or null (unrequested).
  String? _accessStatus;

  /// UI flag to indicate that a network request for access verification is in-flight.
  bool _isAccessLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    
    // Initialize the UI heartbeat timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
    
    // Trigger the initial background access check
    _loadAccess();
  }

  /// Communicates with [AuctionAccessService] to verify the current user's session status.
  Future<void> _loadAccess() async {
    final service = ref.read(auctionAccessServiceProvider);
    final status = await service.checkAccess(
      auctionId: widget.auction.id ?? 0,
      auctionOwnerId: widget.auction.userId,
    );
    if (mounted) {
      setState(() {
        _accessStatus = status;
        _isAccessLoading = false;
      });
    }
  }

  /// Sends a request to the server seeking permission to participate in this auction.
  /// 
  /// If the user is unauthenticated, redirects them to [SignInScreen].
  Future<void> _requestAccess() async {
    if (CachedVariables.userId == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
      return;
    }
    
    setState(() => _isAccessLoading = true);
    
    final service = ref.read(auctionAccessServiceProvider);
    final status = await service.requestAccess(
      auctionId: widget.auction.id ?? 0,
    );
    
    if (mounted) {
      setState(() {
        _accessStatus = status;
        _isAccessLoading = false;
      });
      if (status == 'PENDING') {
        AppFunctions.showSnackBar(
          context: context, 
          message: AppStrings.accessPending.tr(),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Computes time delta between local system clock and server-provided auction schedules.
  void _calculateRemainingTime() {
    final now = DateTime.now();
    
    // Live Start Calculation
    if (widget.auction.liveStartDate != null) {
      final liveStartDate = widget.auction.liveStartDate!;
      setState(() {
        _remainingTimeForLive = liveStartDate.isAfter(now) 
            ? liveStartDate.difference(now) 
            : Duration.zero;
      });
    }

    // Pre-Auction Start Calculation
    if (widget.auction.startDate != null) {
      final startDate = widget.auction.startDate!;
      setState(() {
        _remainingTimeForPreAuction = startDate.isAfter(now) 
            ? startDate.difference(now) 
            : Duration.zero;
      });
    }
  }

  /// Standardizes [Duration] objects into readable 'HH:MM:SS' or 'SS sec' strings.
  String _formatDuration(Duration duration) {
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else if (duration.inMinutes > 0) {
      return '$minutes:$seconds';
    } else {
      return '${duration.inSeconds} sec';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reactive binding to the global favorites/wishlist state
    final favoritesState = ref.watch(favoritesControllerProvider);
    final isLiked = favoritesState.maybeWhen(
      data: (state) => state.likedAuctionIds.contains(widget.auction.id),
      orElse: () => false,
    );
    
    final bool isEnded = widget.auction.isExpired == true;

    // Derived UI metadata based on auction lifecycle
    String? statusLabel;
    Color? statusColor;

    if (isEnded) {
      statusLabel = AppStrings.auctionEnded.tr();
      statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
          // Default tap behavior Navigate to details/pre-auction screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionScreen(widget.auction),
            ),
          );
        },
        onLongPress: () {
          // Convenience feature: Open fullscreen image on long press
          AppFunctions.showImageDialog(
            context: context,
            imageUrl: widget.auction.imageUrl ?? '',
            id: widget.auction.id ?? 0,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Visual Layer (Image & Badges) ───────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: widget.heroTag ?? widget.auction.id ?? 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: widget.auction.imageUrl ?? '',
                        memCacheHeight: 400,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (context, url, progress) => Center(
                          child: CircularProgressIndicator(value: progress.progress),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        ),
                      ),
                    ),
                  ),
                  // Floating Interaction: Wishlist/Like
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildHeartIcon(isLiked),
                  ),
                  // Floating Interaction: Status Badge (e.g. "Ended")
                  if (statusLabel != null)
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      start: 12,
                      top: 12,
                      child: _buildStatusBadge(statusLabel, statusColor),
                    ),
                ],
              ),
            ),

            // ── Information & Metadata Layer ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.auction.localizedTitle(context.locale.languageCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  gapH4,
                  Text(
                    widget.auction.localizedDescription(context.locale.languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                  ),
                  gapH8,
                  
                  // ── Progress Tracker (Countdown or Dates) ──────────────────
                  _buildTimingInfo(isEnded),
                  
                  gapH8,
                  
                  // ── CTA Layer (Context-Aware Action Button) ────────────────
                  if (!isEnded) _buildAccessAwareButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Internal: Builds the favoriting toggle with authentication guard.
  Widget _buildHeartIcon(bool isLiked) {
    return InkWell(
      onTap: () {
        final user = ref.read(authControllerProvider).value;
        if (user == null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => SignInScreen()));
          return;
        }
        ref.read(favoritesControllerProvider.notifier).toggleLikeAuction(widget.auction);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(200), shape: BoxShape.circle),
        child: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  /// Internal: Builds localized status overlays for the card.
  Widget _buildStatusBadge(String label, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  /// Internal: Renders the countdown or formatted date based on auction phase.
  Widget _buildTimingInfo(bool isEnded) {
    if (widget.auction.startDate == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final startDate = widget.auction.startDate!;
    final expiryDate = widget.auction.expiryDate ?? now.add(const Duration(days: 1));

    if (startDate.isAfter(now)) {
      // Future: Not yet in pre-auction phase
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.auction.liveStartDate != null) ...[
            Text(
              '${'preAuctionStartsAt'.tr()}: ${DateFormat('MMM d, h:mm a').format(startDate)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1B5E20)),
            ),
            Text(
              '${'liveStartsAt'.tr()}: ${DateFormat('MMM d, h:mm a').format(widget.auction.liveStartDate!)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          ] else ...[
            Text(
              '${AppStrings.startedAt.tr()}: ${DateFormat('MMM d, h:mm a').format(startDate)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1B5E20)),
            ),
          ],
        ],
      );
    } else if (isEnded) {
      // Archive: Auction has passed its expiry
      return Text(
        '${AppStrings.endedOn.tr()}: ${DateFormat('MMM d, h:mm a').format(expiryDate)}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
      );
    } else {
      // Active: Currently browsing (pre) or bidding (live)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _remainingTimeForPreAuction > Duration.zero
              ? Text(
                  '${AppStrings.remainingTime.tr()} ${AppStrings.untilPreAuction.tr()}: ${_formatDuration(_remainingTimeForPreAuction)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD32F2F)),
                )
              : Text(
                  AppStrings.preAuctionStarted.tr(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                ),
          gapH4,
          Text(
            '${AppStrings.remainingTime.tr()} ${AppStrings.untilLive.tr()}: ${_formatDuration(_remainingTimeForLive)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFD32F2F)),
          ),
        ],
      );
    }
  }

  /// Internal: Core branching logic for the main CTA button.
  /// 
  /// Logic order:
  /// 1. Check if access data is still loading.
  /// 2. If 'GRANTED' and time is right -> "Join Now" (Live Auction).
  /// 3. If 'GRANTED' but not live yet -> "Bid Now" (Pre-Auction).
  /// 4. If 'PENDING' -> Display unclickable status.
  /// 5. If 'DENIED' -> Display error status.
  /// 6. Default -> "Request Access" call-to-action.
  Widget _buildAccessAwareButton() {
    if (_isAccessLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final bool isLiveStarted = _remainingTimeForLive == Duration.zero &&
        _remainingTimeForPreAuction == Duration.zero &&
        widget.auction.startDate != null &&
        widget.auction.startDate!.isBefore(DateTime.now());

    final bool isGranted = _accessStatus == 'GRANTED';
    final bool isPending = _accessStatus == 'PENDING';
    final bool isDenied = _accessStatus == 'DENIED';

    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    if (isGranted && isLiveStarted) {
      buttonText = AppStrings.joinNow.tr();
      buttonColor = Colors.green;
      onPressed = () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => LiveAuctionScreen(
                      auctionId: widget.auction.id ?? 0,
                      isAdmin: widget.auction.userId == CachedVariables.userId,
                    )),
          );
    } else if (isGranted) {
      buttonText = AppStrings.bidNow.tr();
      buttonColor = const Color(0xFF1B5E20);
      onPressed = () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionScreen(widget.auction)));
    } else if (isPending) {
      buttonText = AppStrings.accessPending.tr();
      buttonColor = Colors.orange;
      onPressed = null;
    } else if (isDenied) {
      buttonText = AppStrings.accessDenied.tr();
      buttonColor = Colors.red;
      onPressed = null;
    } else {
      buttonText = AppStrings.requestAccess.tr();
      buttonColor = const Color(0xFF1B5E20);
      onPressed = _requestAccess;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: buttonColor.withAlpha(200),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

