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
    socketActions.leaveAuction(widget.auctionId, CachedVariables.userId!);
    _audioPlayer.dispose();
    super.dispose();
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
      ref.invalidate(auctionDetailsProvider(widget.auctionId));
      resetProductChangeStream(ref);
      resetNewBidStream(ref);

      if (next.valueOrNull?.winnerId == CachedVariables.userId) {
        _audioPlayer.play(AssetSource('sounds/win_bid_notification.wav'));
        FCMService().showLocalNotification(
          title: AppStrings.youWon.tr(),
          body: '${AppStrings.youWon.tr()} ${auction.title ?? ""}',
        );
      } else {
        _audioPlayer.play(AssetSource('sounds/lose_notification.wav'));
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('auctionEnded'.tr()),
            content: Text('${'winner'.tr()} ${next.valueOrNull?.winnerName}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('ok'.tr()),
              ),
            ],
          );
        },
      );
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
                        Builder(
                          builder: (context) {
                            String? statusLabel;
                            Color? statusColor;
                            final int? currentUserId = CachedVariables.userId;
                            final bool isEnded =
                                auction.isExpired == true ||
                                auction.isCanceled == true;

                            if (isEnded) {
                              if (auction.winningUserId == currentUserId) {
                                statusLabel = AppStrings.youWon.tr();
                                statusColor = Colors.green;
                              } else if (auction.auctionBids?.any(
                                    (bid) => bid.userId == currentUserId,
                                  ) ??
                                  false) {
                                statusLabel = AppStrings.youLost.tr();
                                statusColor = Colors.red;
                              } else if (auction.winningUserId != null) {
                                statusLabel = AppStrings.sold.tr();
                                statusColor = Colors.blue;
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
}
