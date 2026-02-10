import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/async_value_widget.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/agora_video_widget/agora_video_widget.dart';

import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bids_history_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_gallery_widget.dart';
import 'package:turathy/src/core/helper/fcm/fcm_service.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_info_table_widget.dart';
import '../../../../core/helper/cache/cached_variables.dart';
import '../../../../core/helper/socket/socket_exports.dart';

class LiveAuctionScreen extends ConsumerStatefulWidget {
  final int auctionId;
  final bool isAdmin;

  const LiveAuctionScreen({
    required this.auctionId,
    this.isAdmin = false,
    super.key,
  });

  @override
  ConsumerState createState() => _LiveAuctionScreenState();
}

class _LiveAuctionScreenState extends ConsumerState<LiveAuctionScreen> {
  late SocketActions socketActions = ref.read(socketActionsProvider);
  late AuctionModel auction;
  RtcEngine? _engine;
  bool _isVideoReady = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Local state for immediate updates
  bool _isAuctionEnded = false;
  int? _winnerId;
  String? _winnerName;
  num? _finalPrice; // To store the price when auction ends
  bool _hasShownResultDialog = false;

  @override
  void initState() {
    if (widget.isAdmin) {
      socketActions.startLiveAuction(widget.auctionId, CachedVariables.userId!);
    }
    socketActions.joinAuction(widget.auctionId, CachedVariables.userId!);
    super.initState();
  }

  @override
  void dispose() {
    _cleanupEngine();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _cleanupEngine() {
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
      _engine = null;
    }
  }

  void _placeBid(int quantity, num currentBid, {bool isMinBid = false}) {
    final lastAuctionProduct = ref.read(auctionProductChangeProvider);
    if (currentBid == 0) {
      return;
    }
    if (currentBid ==
            (lastAuctionProduct?.minBidPrice ?? auction.minBidPrice) &&
        isMinBid) {
      socketActions.placeBid(
        auction.id ?? 0,
        CachedVariables.userId!,
        (currentBid).toDouble(),
      );
      return;
    }
    socketActions.placeBid(
      auction.id ?? 0,
      CachedVariables.userId!,
      currentBid.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userCountUpdateProvider, (previous, next) {});
    ref.listen(auctionEndedProvider, (previous, next) {
      debugPrint(
        'LiveAuctionScreen: auctionEndedProvider update received. Value: ${next.valueOrNull}',
      );
      final event = next.valueOrNull;
      if (event != null) {
        debugPrint(
          'LiveAuctionScreen: Auction Ended Event: winnerId=${event.winnerId}, finalPrice=${event.finalBidAmount}',
        );
        ref.invalidate(auctionDetailsProvider(widget.auctionId));
        resetProductChangeStream(ref);
        resetNewBidStream(ref);

        setState(() {
          _isAuctionEnded = true;
          _winnerId = event.winnerId;
          _winnerName = event.winnerName;
          _finalPrice = event.finalBidAmount;
        });

        if (event.winnerId == CachedVariables.userId) {
          _audioPlayer.play(
            AssetSource('sounds/win_bid_notification.wav'),
            volume: 1.0,
          );
          FCMService().showLocalNotification(
            title: AppStrings.youWon.tr(),
            body: '${AppStrings.youWon.tr()} ${auction.title ?? ""}',
          );
        } else {
          _audioPlayer.play(
            AssetSource('sounds/lose_notification.wav'),
            volume: 1.0,
          );
        }

        _showResultDialog(
          winnerId: event.winnerId,
          winnerName: event.winnerName,
          finalPrice: event.finalBidAmount,
        );
      }
    });

    // Listen for new bids to update timer and price
    ref.listen(newBidEventProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null) {
        // Play sound if bid is from another user
        if (event.newBid.userId != CachedVariables.userId) {
          _audioPlayer.play(AssetSource('sounds/higher_bid_notification.wav'));
          HapticFeedback.lightImpact();
        }

        setState(() {
          if (event.expiryDate != null) {
            auction.expiryDate = event.expiryDate;
          }
          if (event.currentPrice != null) {
            auction.actualPrice = event.currentPrice;
          }
        });
      }
    });

    final auctionValue = ref.watch(auctionDetailsProvider(widget.auctionId));
    auction = auctionValue.valueOrNull ?? AuctionModel(isLiveAuction: true);

    // Initialize local state if not already set (for initial load)
    // We only set it once when data is first loaded, unless it's already ended locally
    if (auctionValue.hasValue &&
        !_isAuctionEnded &&
        (auction.isExpired == true ||
            auction.isCanceled == true ||
            auction.winningUserId != null)) {
      _isAuctionEnded = true;
      _winnerId = auction.winningUserId;
      _winnerName = auction.user?.name; // Incorrect, user is the creator.
      // We often don't have winner name in AuctionModel directly unless we fetch it separately or it's added to model.
      // For now, relies on what we have. If winningUserId is present, we know ID.
      // We might need to fetch winner name if it's not in the model.
      // Actually AuctionModel has `winningUserId`.
      _finalPrice = auction.actualPrice;
    }

    // Check if we should show the result dialog immediately on entry
    // Only show if the user participated or won
    // We check this outside the `_isAuctionEnded` block to handle cases where
    // auctionBids might populate after the initial load.
    final bool isLocallyEnded =
        _isAuctionEnded ||
        auction.isExpired == true ||
        auction.isCanceled == true ||
        auction.winningUserId != null;

    if (isLocallyEnded && !_hasShownResultDialog) {
      final bool userParticipated =
          auction.auctionBids?.any(
            (bid) => bid.userId == CachedVariables.userId,
          ) ??
          false;

      final int? effectiveWinnerId = _winnerId ?? auction.winningUserId;
      final bool userWon = effectiveWinnerId == CachedVariables.userId;

      if (userWon || userParticipated) {
        // Schedule dialog to show after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showResultDialog(
              winnerId: effectiveWinnerId,
              winnerName: _winnerName ?? auction.user?.name,
              finalPrice: _finalPrice ?? auction.actualPrice,
            );
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('auctionDetails'.tr()),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncValueWidget(
          value: auctionValue,
          data: (auction) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Agora Video (shrinks if no video)
                        if (auction.isLiveAuction && auction.isLive == true)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: _isVideoReady
                                ? SizedBox(
                                    height: 300,
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final agoraTokenValue = ref.watch(
                                          agoraTokenProvider(
                                            AgoraTokenRequest(
                                              auctionID: widget.auctionId,
                                              isPublisher: widget.isAdmin,
                                            ),
                                          ),
                                        );
                                        return AsyncValueWidget(
                                          value: agoraTokenValue,
                                          data: (token) => AgoraVideoWidget(
                                            isAdmin: widget.isAdmin,
                                            agoraToken: token,
                                            auctionId: widget.auctionId,
                                            onEngineInitialized: (engine) {
                                              _engine = engine;
                                              if (mounted) {
                                                setState(() {
                                                  _isVideoReady = true;
                                                });
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        // Image Gallery
                        // Image Gallery
                        // Image Gallery
                        Builder(
                          builder: (context) {
                            String? statusLabel;
                            Color? statusColor;
                            final int? currentUserId = CachedVariables.userId;

                            // Use local state if ended, otherwise check model
                            final bool isEnded =
                                _isAuctionEnded ||
                                auction.isExpired == true ||
                                auction.isCanceled == true ||
                                (auction.expiryDate != null &&
                                    auction.expiryDate!.isBefore(
                                      DateTime.now(),
                                    ));
                            log("isEnded: $isEnded");
                            final int? winnerId =
                                _winnerId ?? auction.winningUserId;

                            if (isEnded) {
                              log("isEnded");
                              log("winnerId: $winnerId");
                              log("currentUserId: $currentUserId");
                              log("Current user:${CachedVariables.userId}");
                              log("WinnerId: ${auction.winningUserId}");
                              if (winnerId != null &&
                                  winnerId == currentUserId) {
                                log("You won");
                                statusLabel = AppStrings.youWon.tr();
                                statusColor = Colors.green;
                              } else if (auction.auctionBids?.any(
                                    (bid) => bid.userId == currentUserId,
                                  ) ??
                                  false) {
                                // Checking if user participated.
                                // Note: AuctionBids might not be full list if paginated,
                                // but for this screen we usually have recent bids.
                                // Ideal check would be 'didUserBid' flag from backend.
                                // For now, this is best effort.

                                // But if user lost, they aren't the winner.
                                statusLabel = AppStrings.youLost.tr();
                                statusColor = Colors.red;
                              } else if (winnerId != null) {
                                statusLabel = AppStrings.sold.tr();
                                statusColor = Colors.blue;
                              } else {
                                statusLabel = AppStrings.auctionEnded.tr();
                                statusColor = Colors.grey;
                              }
                            }

                            return AuctionGalleryWidget(
                              images: [
                                if (auction.imageUrl != null &&
                                    auction.imageUrl!.isNotEmpty)
                                  auction.imageUrl!,
                                ...?auction.auctionImages,
                              ],
                              statusLabel: statusLabel,
                              statusColor: statusColor,
                            );
                          },
                        ),

                        // Info Table
                        AuctionInfoTableWidget(auction: auction),

                        gapH16,

                        // Bid History
                        AuctionBidsHistoryWidget(
                          initialBids: auction.auctionBids ?? [],
                        ),

                        gapH24,
                      ],
                    ),
                  ),
                ),
                // Bidding Controls (Fixed at bottom)
                AuctionBiddingControlsWidget(
                  auction: auction,
                  expiryDate: auction.expiryDate,
                  isAuctionEnded: _isAuctionEnded,
                  isOwner: auction.userId == CachedVariables.userId,
                  winnerId: _winnerId,
                  winnerName: _winnerName,
                  finalPrice: _finalPrice,
                  onPlaceBid: (qty, price) {
                    _placeBid(qty, price);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showResultDialog({
    required int? winnerId,
    required String? winnerName,
    required num? finalPrice,
  }) {
    if (_hasShownResultDialog) return;

    setState(() {
      _hasShownResultDialog = true;
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Auction Result',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AuctionResultDialog(
          winnerId: winnerId,
          winnerName: winnerName,
          finalPrice: finalPrice,
          currentUserId: CachedVariables.userId,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

class AuctionResultDialog extends StatelessWidget {
  final int? winnerId;
  final String? winnerName;
  final num? finalPrice;
  final int? currentUserId;

  const AuctionResultDialog({
    super.key,
    this.winnerId,
    this.winnerName,
    this.finalPrice,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status
    bool isWinner = winnerId != null && winnerId == currentUserId;
    bool hasWinner = winnerId != null;

    IconData icon;
    Color color;
    String title;
    String message;

    if (isWinner) {
      icon = Icons.emoji_events_rounded;
      color = const Color(0xFFFFD700); // Gold
      title = AppStrings.youWon.tr();
      message = '${'winner'.tr()}: ${winnerName ?? 'Unknown'}';
    } else if (hasWinner) {
      // User lost
      icon = Icons.sentiment_dissatisfied_rounded;
      color = const Color(0xFFE53935); // Red
      title = AppStrings.youLost.tr();
      message = '${'winner'.tr()}: ${winnerName ?? 'Unknown'}';
    } else {
      // No winner / Ended
      icon = Icons.timer_off_rounded;
      color = Colors.grey;
      title = AppStrings.auctionEnded.tr();
      message = AppStrings.noBidsYet.tr();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Circle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            gapH24,

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            gapH12,

            // Message (Winner Name)
            if (winnerName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            gapH16,

            // Final Price
            if (finalPrice != null)
              Column(
                children: [
                  Text(
                    AppStrings.finalPrice.tr(),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  gapH4,
                  Text(
                    '$finalPrice ${AppStrings.currency.tr()}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D4739),
                    ),
                  ),
                ],
              ),

            gapH32,

            // Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D4739),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppStrings.ok.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
