import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/common_widgets/async_value_widget.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/notifications/presentation/notifications_screen.dart';
// import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/agora_video_widget/agora_video_widget.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';

import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/fcm/fcm_service.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_item_details_widget.dart';
import 'package:turathy/src/features/orders/presentation/order_confirmation_screen.dart';
import 'package:turathy/src/features/orders/presentation/order_details_screen.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bids_history_widget.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import '../../domain/winning_auction_model.dart';
import '../../../../core/helper/cache/cached_variables.dart';
import '../../../../core/helper/socket/socket_exports.dart';
import 'package:turathy/src/features/auctions/domain/auction_access_model.dart';

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
  // RtcEngine? _engine;
  // video flag removed - not used anymore
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();

  // Local state for immediate updates
  bool _isAuctionEnded = false;
  int? _winnerId;
  String? _winnerName;
  num? _finalPrice; // To store the price when auction ends
  //bool _hasShownResultDialog = false;
  // True only after a live event fires — prevents showing result dialog
  // when the user enters an already-finished auction.
  bool _wasLiveWhenJoined = false;

  // True only when the auction initially loads as already-ended via the API.
  //bool _apiLoadedAsEnded = false;

  // Selected product for view-only mode
  AuctionProducts? _selectedProduct;

  // Access Control State
  String _accessStatus =
      'LOADING'; // 'LOADING', 'GRANTED', 'REQUIRED', 'PENDING', 'DENIED'
  bool _isAccessLoading = true;

  // Prevents the post-frame scroll from firing on every rebuild
  bool _hasInitiallyScrolled = false;

  StreamSubscription? _socketErrorSubscription;
  StreamSubscription? _bidRejectedSubscription;

  @override
  void initState() {
    super.initState();
    _checkAccess();

    // Listen to socket errors (e.g., "Max bid limit exceeded")

    // Using socketServiceProvider directly to get access to getEventStream
    final socketService = ref.read(socketServiceProvider);
    _socketErrorSubscription = socketService
        .getEventStream<dynamic>('error', (data) => data)
        .listen((data) {
          if (mounted && data != null) {
            final message = data['message'] ?? data.toString();

            // Check if message is related to bid limit
            if (message.toString().toLowerCase().contains(
              'max bid limit exceeded',
            )) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.bidLimitExceeded.tr()),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              // Display other errors generic or as they come
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });

    // Listen for bid rejections caused by stale price (out-of-sync).
    // The server sends the real current price so we can self-correct instantly
    // without triggering an HTTP request.
    _bidRejectedSubscription = socketService
        .getEventStream<dynamic>('bidRejected', (data) => data)
        .listen((data) {
          if (!mounted || data == null) return;
          final serverPrice = (data['currentPrice'] as num?);
          final minBid = (data['minimumBid'] as num?);
          if (serverPrice != null) {
            setState(() {
              auction.actualPrice = serverPrice;
            });
          }
          final hint = minBid != null ? ' (min: $minBid)' : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'priceUpdatedRetry'.tr()}$hint'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        });
  }

  Future<void> _checkAccess() async {
    if (widget.isAdmin) {
      setState(() {
        _accessStatus = 'GRANTED';
        _isAccessLoading = false;
      });
      socketActions.startLiveAuction(widget.auctionId, CachedVariables.userId!);
      socketActions.joinAuction(widget.auctionId, CachedVariables.userId!);
      return;
    }

    try {
      final repository = ref.read(productsRepositoryProvider);
      final response = await repository.checkUserAccess(
        CachedVariables.userId ?? 0,
        widget.auctionId,
      );

      setState(() {
        _accessStatus = response.status.toUpperCase();
        _isAccessLoading = false;
      });

      if (_accessStatus == 'GRANTED') {
        socketActions.joinAuction(widget.auctionId, CachedVariables.userId!);
      }
    } catch (e) {
      debugPrint("Error checking auction access: $e");
      setState(() {
        _accessStatus = 'ERROR';
        _isAccessLoading = false;
      });
    }
  }

  Future<void> _requestAccess() async {
    setState(() {
      _isAccessLoading = true;
    });
    try {
      final repository = ref.read(productsRepositoryProvider);
      final response = await repository.requestAccess(
        RequestAuctionAccessDto(
          userId: CachedVariables.userId ?? 0,
          auctionId: widget.auctionId,
        ),
      );
      setState(() {
        _accessStatus = response.status.toUpperCase();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.accessPending.tr()),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint("Error requesting auction access: $e");
    } finally {
      setState(() {
        _isAccessLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // _cleanupEngine();
    _socketErrorSubscription?.cancel();
    _bidRejectedSubscription?.cancel();
    _cancelFailSafeTimer();
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // void _cleanupEngine() {
  //   if (_engine != null) {
  //     _engine!.leaveChannel();
  //     _engine!.release();
  //     _engine = null;
  //   }
  // }

  bool _isSameProduct(String? p1, String? p2) {
    if (p1 == null && p2 == null) return true;
    if (p1 == null || p2 == null) return false;
    return p1.trim().toLowerCase() == p2.trim().toLowerCase();
  }

  /// Picks the next product in the auctionProducts list relative to the
  /// current live product. If the current product isn't found or there is no
  /// next item, [_selectedProduct] is set to null.
  void _selectNextProduct() {
    if (auction.auctionProducts == null || auction.auctionProducts!.isEmpty) {
      _selectedProduct = null;
      return;
    }

    final currentIndex = auction.auctionProducts!.indexWhere(
      (p) => _isSameProduct(p.displayName, auction.currentProduct),
    );

    if (currentIndex == -1 ||
        currentIndex + 1 >= auction.auctionProducts!.length) {
      // nothing to select (could also clear to let user pick any)
      _selectedProduct = null;
    } else {
      _selectedProduct = auction.auctionProducts![currentIndex + 1];
    }
  }

  void _placeBid(
    int quantity,
    num currentBid, {
    bool isMinBid = false,
    int? overrideProductId,
  }) {
    if (currentBid == 0) {
      return;
    }

    AuctionProducts? productToBidOn;

    if (overrideProductId != null) {
      productToBidOn = auction.auctionProducts?.firstWhere(
        (element) => element.id == overrideProductId,
        orElse: () => AuctionProducts(),
      );
    } else {
      productToBidOn = auction.auctionProducts?.firstWhere(
        (element) =>
            element.displayName == auction.currentProduct ||
            element.id == auction.currentProductId,
        orElse: () => AuctionProducts(),
      );
    }

    if (productToBidOn == null || productToBidOn.id == null) {
      debugPrint(
        'LiveAuctionScreen: Cannot place bid. Product not found: ${auction.currentProduct}',
      );
      return;
    }

    final lastAuctionProduct = ref.read(auctionProductChangeProvider);

    if (currentBid ==
            (lastAuctionProduct?.minBidPrice ?? auction.minBidPrice) &&
        isMinBid) {
      socketActions.placeBid(
        auction.id ?? 0,
        CachedVariables.userId!,
        (currentBid).toDouble(),
        productToBidOn.id!,
      );
      return;
    }
    socketActions.placeBid(
      auction.id ?? 0,
      CachedVariables.userId!,
      currentBid.toDouble(),
      productToBidOn.id!,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep socket bids alive while the parent screen is open
    ref.watch(accumulatedBidsProvider);
    ref.watch(latestExpiryDateStateProvider);
    // Activate rolling-sequence gap detection for this screen.
    ref.watch(auctionGapDetectedProvider);

    ref.listen(userCountUpdateProvider, (previous, next) {});

    // Listen for pre-auction start
    ref.listen(auctionPreStartedProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null) {
        setState(() {
          auction = event;
          if (event.liveStartDate != null) {
            _scheduleFailSafeTimer(event.liveStartDate!);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('preAuctionPhase'.tr()),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    // Listen for Auction Item Ended (Multi-item transition)
    ref.listen(auctionItemEndedProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null) {
        // Cancel fail-safe timer as we got the event
        _cancelFailSafeTimer();

        // Mark that the user was live during this auction
        _wasLiveWhenJoined = true;

        // play sound/notification but do not show popup dialog
        if (event.winner != null && _wasLiveWhenJoined) {
          if (event.winner!.id == CachedVariables.userId) {
            _audioPlayer.play(
              AssetSource('sounds/win_bid_notification.wav'),
              volume: 1.0,
            );
            FCMService().showLocalNotification(
              title: AppStrings.youWon.tr(),
              body: '${AppStrings.youWon.tr()} ${auction.currentProduct ?? ""}',
            );
          } else {
            // Check if current user actually participated in this item
            final currentItemBids =
                auction.auctionBids
                    ?.where((b) => b.productId == auction.currentProductId)
                    .toList() ??
                [];
            final didIParticipate = currentItemBids.any(
              (b) => b.userId == CachedVariables.userId,
            );

            if (didIParticipate) {
              _audioPlayer.play(
                AssetSource('sounds/lose_notification.wav'),
                volume: 1.0,
              );
            }
          }
        }

        if (event.nextItem != null) {
          // Transition to the next item
          setState(() {
            // Update auction details
            auction.currentProduct = event.nextItem!.displayName;
            auction.currentProductId = event.nextItem!.id;
            auction.actualPrice =
                num.tryParse(event.nextItem!.actualPrice ?? '0') ?? 0;
            auction.minBidPrice =
                num.tryParse(event.nextItem!.minBidPrice ?? '0') ?? 0;
            auction.bidPrice =
                num.tryParse(event.nextItem!.bidPrice ?? '0') ?? 0;
            if (event.nextItem!.imageUrl != null) {
              auction.imageUrl = event.nextItem!.imageUrl;
            }

            // Calculate new expiry based on duration (or specific field if available)
            if (event.auction.expiryDate != null) {
              auction.expiryDate = event.auction.expiryDate;
            }

            // Reset local state for new item
            _isAuctionEnded = false;
            _winnerId = null;
            _winnerName = null;
            _finalPrice = null;
            //_hasShownResultDialog = false;
            // auto-select the incoming product so the UI highlights it
            if (event.nextItem!.id != null &&
                auction.auctionProducts != null &&
                auction.auctionProducts!.isNotEmpty) {
              _selectedProduct = auction.auctionProducts!.firstWhere(
                (p) => p.id == event.nextItem!.id,
                orElse: () => event.nextItem!,
              );
            } else {
              _selectedProduct = event.nextItem;
            }

            // Auto-scroll to new item
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentItem();
            });
          });

          // Schedule next fail-safe for the new item
          if (auction.expiryDate != null) {
            _scheduleFailSafeTimer(auction.expiryDate!);
          }
        } else {
          // no next item means the final product has ended; clear live marker
          setState(() {
            _isAuctionEnded = true;
            // still advance selection based on positional logic
            _selectNextProduct();
            auction.currentProduct = null;
            auction.currentProductId = null;
          });
        }
      }
    });

    ref.listen(auctionEndedProvider, (previous, next) {
      debugPrint(
        'LiveAuctionScreen: auctionEndedProvider update received. Value: ${next.valueOrNull}',
      );
      final event = next.valueOrNull;
      if (event != null) {
        _cancelFailSafeTimer(); // Cancel timer

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
          // advance selection using badge logic (pick next index)
          _selectNextProduct();
          // clear currentProduct so the thumbnail badge is no longer marked LIVE
          auction.currentProduct = null;
          auction.currentProductId = null;
        });

        if (event.winnerId == CachedVariables.userId) {
          _audioPlayer.play(
            AssetSource('sounds/win_bid_notification.wav'),
            volume: 1.0,
          );
          FCMService().showLocalNotification(
            title: AppStrings.youWon.tr(),
            body: '${AppStrings.youWon.tr()} ${auction.displayTitle}',
          );
        } else {
          // Check if current user actually participated in the final item
          final lastProductId = auction.currentProductId;
          final lastItemBids =
              auction.auctionBids
                  ?.where((b) => b.productId == lastProductId)
                  .toList() ??
              [];
          final didIParticipate = lastItemBids.any(
            (b) => b.userId == CachedVariables.userId,
          );

          if (didIParticipate) {
            _audioPlayer.play(
              AssetSource('sounds/lose_notification.wav'),
              volume: 1.0,
            );
          }
        }
        // We intentionally no longer pop up a result dialog on the live screen.
        // The bottom bidding controls already reflect the winner/loser state.
      }
    });

    // Listen for new bids to update timer and price
    ref.listen(newBidEventProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null) {
        // Mark that the user was present during a live auction
        _wasLiveWhenJoined = true;

        // Play sound if bid is from another user
        if (event.newBid.userId != CachedVariables.userId) {
          _audioPlayer.play(AssetSource('sounds/higher_bid_notification.wav'));
          HapticFeedback.lightImpact();
        }

        setState(() {
          if (event.expiryDate != null) {
            auction.expiryDate = event.expiryDate;
            _scheduleFailSafeTimer(event.expiryDate!); // Reschedule fail-safe
          }
          if (event.currentPrice != null) {
            auction.actualPrice = event.currentPrice;
          }
        });
      }
    });

    final auctionValue = ref.watch(auctionDetailsProvider(widget.auctionId));
    auction = auctionValue.valueOrNull ?? AuctionModel(isLiveAuction: true);

    // Sync auction pricing fields with the current product's pricing
    if (auction.auctionProducts != null &&
        auction.auctionProducts!.isNotEmpty) {
      // Find the product that matches the current_product name or ID
      final currentProductObj = auction.auctionProducts!.firstWhere(
        (p) =>
            p.displayName == auction.currentProduct ||
            p.id == auction.currentProductId,
        orElse: () => auction.auctionProducts![0],
      );

      // Update pricing fields on the main auction object for the UI to use
      if (currentProductObj.productAr != null ||
          currentProductObj.productEn != null) {
        if (currentProductObj.minBidPrice != null) {
          auction.minBidPrice =
              num.tryParse(currentProductObj.minBidPrice!) ??
              auction.minBidPrice;
        }
        if (currentProductObj.bidPrice != null) {
          auction.bidPrice =
              num.tryParse(currentProductObj.bidPrice!) ?? auction.bidPrice;
        }

        if (currentProductObj.actualPrice != null) {
          auction.actualPrice =
              num.tryParse(currentProductObj.actualPrice!) ??
              auction.actualPrice;
        }
      }
    }

    // Initial Fail-Safe Schedule
    if (auction.expiryDate != null && !_isAuctionEnded) {
      _scheduleFailSafeTimer(auction.expiryDate!);
    }

    // Initialize local state if not already set (for initial load)
    // We only set it once when data is first loaded, unless it's already ended locally
    if (auctionValue.hasValue &&
        !_isAuctionEnded &&
        (auction.isExpired == true ||
            auction.isCanceled == true ||
            auction.winningUserId != null)) {
      _isAuctionEnded = true;
      //_apiLoadedAsEnded = true;
      _winnerId = auction.winningUserId;
      _winnerName = auction.user?.name;
      _finalPrice = auction.actualPrice;

      // Auto-select the last item on the products list if the auction has ended upon load
      if (auction.auctionProducts != null &&
          auction.auctionProducts!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedProduct == null) {
            setState(() {
              _selectedProduct = auction.auctionProducts!.last;
            });
          }
        });
      }
    }

    // Attempt to scroll to current item on initial load only
    // Socket event handlers handle scrolling on item transitions
    if (!_hasInitiallyScrolled &&
        auctionValue.hasValue &&
        auction.auctionProducts != null &&
        auction.auctionProducts!.isNotEmpty) {
      _hasInitiallyScrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentItem();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          auction.currentProduct ??
              (auction.titleAr ?? auction.titleEn ?? 'auctionDetails'.tr()),
        ),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(child: _buildBodyContent()),
    );
  }

  Widget _buildBodyContent() {
    if (_isAccessLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_accessStatus != 'GRANTED') {
      return _buildAccessOverlay();
    }

    final auctionValue = ref.watch(auctionDetailsProvider(widget.auctionId));

    return AsyncValueWidget(
      value: auctionValue,
      data: (auction) {
        final activeProduct =
            _selectedProduct ??
            auction.auctionProducts?.firstWhere((p) {
              return p.displayName == auction.currentProduct ||
                  p.id == auction.currentProductId;
            }, orElse: () => AuctionProducts());

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Agora Video (shrinks if no video)
                    /* 
                        // video feature currently disabled
                        if (auction.isLiveAuction && auction.isLive == true)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: SizedBox(
                                    height: 300,
                                    // AgoraVideoWidget removed
                                    ),
                          ),
                        */

                    // Pre-Auction Indicator
                    if (auction.isPreAuction &&
                        !_isAuctionEnded &&
                        auction.liveStartDate != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.blue.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${'preAuctionPhase'.tr()} - ${'liveStartsAt'.tr()}: ${DateFormat('MMM d, h:mm a').format(auction.liveStartDate!)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Current Product Indicator (New)
                    if (auction.currentProduct != null && !_isAuctionEnded)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.amber.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.label_outline,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${AppStrings.currentItem.tr()}: ${auction.currentProduct}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Items List (Horizontal scrollable)
                    if (auction.auctionProducts != null &&
                        auction.auctionProducts!.isNotEmpty)
                      Container(
                        height: 80,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: auction.auctionProducts!.length,
                          itemBuilder: (context, index) {
                            final item = auction.auctionProducts![index];
                            final bool isLive =
                                item.displayName == auction.currentProduct ||
                                item.id == auction.currentProductId;
                            final bool isSelected =
                                item.id ==
                                (_selectedProduct?.id ??
                                    (auction.auctionProducts
                                            ?.firstWhere(
                                              (p) =>
                                                  p.displayName ==
                                                  auction.currentProduct,
                                              orElse: () => AuctionProducts(),
                                            )
                                            .id ??
                                        auction.currentProductId));

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProduct = item;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isLive
                                        ? Colors
                                              .red // Red border for LIVE item
                                        : isSelected
                                        ? Colors
                                              .blue // Blue border for SELECTED item
                                        : Colors.transparent,
                                    width: (isLive || isSelected) ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CachedNetworkImage(
                                        imageUrl: item.imageUrl ?? '',
                                        memCacheHeight: 150,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const SizedBox(),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.error),
                                      ),
                                    ),
                                    // Status Badge Logic
                                    Builder(
                                      builder: (context) {
                                        // 1. Determine "Phase" of this item relative to current live item
                                        // Assuming list is ordered:
                                        // Index < CurrentIndex -> Past/Sold
                                        // Index == CurrentIndex -> Live
                                        // Index > CurrentIndex -> Future

                                        // Find index of current product
                                        final currentIndex = auction
                                            .auctionProducts!
                                            .indexWhere(
                                              (p) => _isSameProduct(
                                                p.displayName,
                                                auction.currentProduct,
                                              ),
                                            );
                                        // If current product not found (e.g. auction ended completely), maybe all are sold?
                                        // Or if auction just started?

                                        // If auction is ended manually, all past items are sold/won.

                                        if (isLive) {
                                          return Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: Colors.red.withValues(
                                                alpha: 0.8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2,
                                                  ),
                                              child: Text(
                                                AppStrings.live.tr(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        }

                                        if (currentIndex != -1 &&
                                            index > currentIndex) {
                                          // Future Update
                                          // Maybe no badge, or "WAIT"
                                          return const SizedBox.shrink();
                                        }

                                        // FIX: If current product is not found (e.g. startup or mismatch)
                                        // and auction is active, do NOT show "Sold" for everything.
                                        if (currentIndex == -1 &&
                                            !_isAuctionEnded &&
                                            (auction.isCanceled != true &&
                                                auction.isExpired != true)) {
                                          return const SizedBox.shrink();
                                        }

                                        // If we are here, it's either Past (Sold/Expired) or auction ended completely

                                        // Use per-product bids (item.bids) which are populated from the API
                                        // This is more reliable than auction.auctionBids which may be stale after socket events
                                        final productBids = item.bids ?? [];

                                        // Determine winner of this item (highest bid wins)
                                        AuctionBid? highestBid;
                                        if (productBids.isNotEmpty) {
                                          final sorted = [...productBids]
                                            ..sort(
                                              (a, b) => (b.bid ?? 0).compareTo(
                                                a.bid ?? 0,
                                              ),
                                            );
                                          highestBid = sorted.first;
                                        }

                                        late String badgeText;
                                        Color badgeColor = Colors.grey;

                                        final currentUserId =
                                            CachedVariables.userId;

                                        if (highestBid != null) {
                                          if (highestBid.userId ==
                                              currentUserId) {
                                            // User has the highest bid - they won
                                            badgeText = AppStrings.youWon.tr();
                                            badgeColor = Colors.green;
                                          } else {
                                            // Someone else won - check if user participated
                                            final didParticipate = productBids
                                                .any(
                                                  (b) =>
                                                      b.userId == currentUserId,
                                                );
                                            if (didParticipate) {
                                              // User bid but lost
                                              badgeText = AppStrings.youLost
                                                  .tr();
                                              badgeColor = Colors.red;
                                            } else {
                                              // Someone else won and user didn't participate
                                              badgeText = AppStrings.sold.tr();
                                              badgeColor = Colors.grey;
                                            }
                                          }
                                        } else {
                                          // No bids at all - expired
                                          badgeText = AppStrings.expired.tr();
                                          badgeColor = Colors.grey;
                                        }

                                        return Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            color: badgeColor.withValues(
                                              alpha: 0.9,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Image Gallery and Info Table
                    AuctionItemDetailsWidget(
                      auction: auction,
                      activeProduct: activeProduct,
                      isAuctionEnded: _isAuctionEnded,
                    ),

                    gapH16,

                    // Bid History
                    AuctionBidsHistoryWidget(
                      initialBids: auction.auctionBids ?? [],
                      productId: activeProduct?.id,
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
              isViewOnly:
                  !auction.isPreAuction &&
                  _selectedProduct != null &&
                  _selectedProduct?.id !=
                      (auction.auctionProducts
                              ?.firstWhere(
                                (p) => p.displayName == auction.currentProduct,
                                orElse: () => AuctionProducts(),
                              )
                              .id ??
                          auction.currentProductId),
              selectedProduct: _selectedProduct,
              isOwner: auction.userId == CachedVariables.userId,
              winnerId: _winnerId,
              winnerName: _winnerName,
              finalPrice: _finalPrice,
              onPlaceBid: (qty, price, productId) {
                _placeBid(qty, price, overrideProductId: productId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccessOverlay() {
    IconData icon;
    Color color;
    String title;
    String message = AppStrings.requestAccessDescription.tr();
    Widget? actionWidget;

    switch (_accessStatus) {
      case 'PENDING':
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        title = AppStrings.accessPending.tr();
        break;
      case 'DENIED':
        icon = Icons.block;
        color = Colors.red;
        title = AppStrings.accessDenied.tr();
        break;
      case 'REQUIRED':
      default:
        icon = Icons.lock_outline;
        color = Colors.blueGrey;
        title = AppStrings.requestAccess.tr();
        actionWidget = ElevatedButton.icon(
          onPressed: _requestAccess,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: Text(
            AppStrings.requestAccess.tr(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D4739),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: color),
            ),
            gapH24,
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            gapH16,
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            if (actionWidget != null) ...[gapH32, actionWidget],
          ],
        ),
      ),
    );
  }

  void _scrollToCurrentItem() {
    if (!mounted ||
        auction.auctionProducts == null ||
        auction.auctionProducts!.isEmpty) {
      return;
    }

    final index = auction.auctionProducts!.indexWhere(
      (p) =>
          p.displayName == auction.currentProduct ||
          p.id == auction.currentProductId,
    );

    if (index != -1 && _scrollController.hasClients) {
      // Calculate offset: item width (60) + margin (8) = 68
      // Add padding (16) to center or start?
      // Simple offset: index * 68
      final double offset = index * 68.0;

      // Check if already visible is hard with simple calculation, so just animate to it
      // But don't animate if the user is actively scrolling?
      // For "auto select" usually we force it on event.

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Fail-Safe Timer Logic
  Timer? _failSafeTimer;

  void _scheduleFailSafeTimer(DateTime expiry) {
    _cancelFailSafeTimer(); // Cancel any existing timer

    final now = DateTime.now();
    // Schedule for expiry + 2 seconds
    final difference = expiry.difference(now) + const Duration(seconds: 2);

    if (difference.isNegative) {
      // If already past due + 2s, trigger immediately (or maybe connection just established)
      // But we should be careful not to trigger if we just loaded and it's old.
      // Let's only trigger if it's "reasonably" close, effectively a poll.
      // For now, if it's past, trigger it.
      _triggerFailSafe();
    } else {
      _failSafeTimer = Timer(difference, _triggerFailSafe);
    }
  }

  void _cancelFailSafeTimer() {
    _failSafeTimer?.cancel();
    _failSafeTimer = null;
  }

  void _triggerFailSafe() {
    debugPrint(
      "LiveAuctionScreen: Fail-safe timer triggered. Polling for updates.",
    );
    _cancelFailSafeTimer();
    // Refresh the provider to get latest data from backend
    ref.invalidate(auctionDetailsProvider(widget.auctionId));
  }
}

class AuctionResultDialog extends ConsumerWidget {
  final int? winnerId;
  final String? winnerName;
  final num? finalPrice;
  final int? currentUserId;
  final AuctionModel auction;

  const AuctionResultDialog({
    super.key,
    this.winnerId,
    this.winnerName,
    this.finalPrice,
    this.currentUserId,
    required this.auction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      title = AppStrings.ended.tr();
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
              color: Colors.black.withValues(alpha: 0.2),
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
                color: color.withValues(alpha: 0.1),
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
              child: isWinner
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        final currentProductId =
                            auction.auctionProducts
                                ?.firstWhere(
                                  (p) =>
                                      p.displayName == auction.currentProduct,
                                  orElse: () => AuctionProducts(),
                                )
                                .id ??
                            auction.currentProductId ??
                            0;

                        Navigator.of(context).pop();

                        // Check existing orders directly from provider state
                        final ordersValue = ref.read(
                          getUserOrdersProvider(currentUserId ?? 0).future,
                        );

                        try {
                          final orders = await ordersValue;
                          final existingOrder = orders.firstWhere(
                            (o) =>
                                o.auctionId == auction.id &&
                                o.items.any(
                                  (item) =>
                                      item.productId == currentProductId ||
                                      item.auctionProductId == currentProductId,
                                ),
                            orElse: () => OrderModel(
                              id: -1,
                              userId: -1,
                              total: 0,
                              itemDesc: '',
                              items: const [],
                              createdAt: DateTime.now(),
                              auctionId: -1,
                              pCs: 0,
                              codAmt: "0",
                              weight: "0",
                              date: DateTime.now(),
                            ),
                          );

                          if (existingOrder.id != -1 && context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailsScreen(order: existingOrder),
                              ),
                            );
                            return;
                          }
                        } catch (e) {
                          debugPrint("Error fetching orders: $e");
                        }

                        if (!context.mounted) return;

                        final winningModel = WinningAuctionModel(
                          id: 0,
                          userId: currentUserId ?? 0,
                          auctionId: auction.id ?? 0,
                          product: auction.currentProduct ?? '',
                          productId: currentProductId,
                          price: (finalPrice ?? 0).toDouble(),
                          sold: false,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          auctionTitle: auction.displayTitle,
                          auctionStartDate: auction.startDate ?? DateTime.now(),
                          winnerName: winnerName ?? '',
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrderConfirmationScreen(
                              order: OrderModel.fromWinningAuction(
                                winningModel,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, color: Colors.white),
                      label: Text(
                        AppStrings.continueToOrder.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D4739),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    )
                  : ElevatedButton(
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
