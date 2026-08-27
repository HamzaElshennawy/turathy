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
import 'package:turathy/src/core/constants/app_functions/app_functions.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/notifications/presentation/notifications_screen.dart';
// import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/agora_video_widget/agora_video_widget.dart';

import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/analytics/analytics_service.dart';
import 'package:turathy/src/core/helper/fcm/fcm_service.dart';
import 'package:turathy/src/core/helper/fcm/live_room_visibility.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/utils/auction_details_helper.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_main_image_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_item_title_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_thumbnails_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_item_description_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bids_history_widget.dart';
import 'package:turathy/src/core/helper/share/item_share_helper.dart';
import 'package:turathy/src/core/helper/share/item_share_sheet.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';
import 'package:turathy/src/core/helper/locale/app_locale_sync.dart';
import 'package:turathy/src/core/helper/lot_result_status.dart';
import '../../../../core/helper/cache/cached_variables.dart';
import '../../../../core/helper/socket/socket_exports.dart';
import 'package:turathy/src/core/helper/live_bid_sync.dart';

import 'package:turathy/src/features/auctions/data/auction_access_service.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/lot_result_banner.dart';

class LiveAuctionScreen extends ConsumerStatefulWidget {
  final int auctionId;
  final bool isAdmin;

  /// Whether this screen is currently visible. Delegates to [LiveRoomVisibility]
  /// so FCM can suppress bid heads-up without an import cycle.
  static ValueNotifier<bool> get isViewing => LiveRoomVisibility.isViewing;

  const LiveAuctionScreen({
    required this.auctionId,
    this.isAdmin = false,
    super.key,
  });

  @override
  ConsumerState createState() => _LiveAuctionScreenState();
}

class _LiveAuctionScreenState extends ConsumerState<LiveAuctionScreen>
    with WidgetsBindingObserver {
  late SocketActions socketActions = ref.read(socketActionsProvider);
  AuctionModel auction = AuctionModel(isLiveAuction: true);
  // RtcEngine? _engine;
  // video flag removed - not used anymore
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  final PageController _mainImagePageController = PageController();
  int _currentMainImageIndex = 0;

  // Local state for immediate updates
  bool _isAuctionEnded = false;
  int? _winnerId;
  String? _winnerName;
  num? _finalPrice; // To store the price when auction ends
  //bool _hasShownResultDialog = false;
  // True only after a live event fires — prevents showing result dialog
  // when the user enters an already-finished auction.
  //bool _wasLiveWhenJoined = false;

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

  // Tracks winners per product from live auctionItemEnded events.
  // Key: productId, Value: winner SocketUser
  final Map<int, SocketUser> _productWinners = {};

  // Explicit isSold from auctionItemEnded / product payload. Bids never imply sold.
  final Map<int, bool> _productSold = {};

  // Tracks which products the current user participated in (bid on) during
  // this live session — used for badge rendering when item.bids is stale.
  final Set<int> _productParticipants = {};

  LotResultKind? _lotResult;
  Timer? _lotResultTimer;

  StreamSubscription? _socketErrorSubscription;
  StreamSubscription? _bidRejectedSubscription;
  StreamSubscription? _bidAcceptedSubscription;
  StreamSubscription? _auctionSyncSubscription;
  DateTime? _scheduledFailSafeExpiry;
  DateTime? _failSafeFiredForExpiry;
  num? _liveCurrentPrice;
  DateTime? _liveExpiryDate;
  bool _suppressSwipe = false;
  Timer? _swipeHideTimer;

  @override
  void initState() {
    super.initState();
    LiveRoomVisibility.isViewing.value = true;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.logScreenView(
        screenName: 'live_auction',
        screenClass: 'LiveAuctionScreen',
      );
      AnalyticsService.logAuctionJoined(auctionId: widget.auctionId);
      if (!mounted) return;
      final loaded = ref.read(auctionDetailsProvider(widget.auctionId)).valueOrNull;
      if (loaded?.expiryDate != null && !_isAuctionEnded) {
        _scheduleFailSafeTimer(loaded!.expiryDate!);
      }
    });
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
              AppFunctions.showSnackBar(
                context: context,
                message: AppStrings.bidLimitExceeded.tr(),
                isError: true,
              );
            } else {
              // Display other errors generic or as they come
              AppFunctions.showSnackBar(
                context: context,
                message: message.toString(),
                isError: true,
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
          if (serverPrice != null) {
            _applyRoomBidUpdate(currentPrice: serverPrice);
          }
          AppFunctions.showSnackBar(
            context: context,
            message: 'priceUpdatedRetry'.tr(),
            icon: Icons.info_outline,
          );
        });

    // Per-sender ACK: the server emits 'bidAccepted' only to the bidding
    // socket, so this is the reliable place for success feedback.
    _bidAcceptedSubscription = socketService
        .getEventStream<dynamic>('bidAccepted', (data) => data)
        .listen((data) {
          if (!mounted || data == null) return;
          final map = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
          _applyRoomBidUpdate(
            currentPrice: parseBidAcceptedPrice(map),
            expiryDate: parseSocketDate(map['expiryDate']),
            eventProductId: parsePositiveInt(map['productId'] ?? map['product_id']),
          );
          final rawBids = map['auctionBids'];
          if (rawBids is List) {
            for (final raw in rawBids.whereType<Map>()) {
              ref.read(accumulatedBidsProvider.notifier).addBid(
                    AuctionBid.fromJson(Map<String, dynamic>.from(raw)),
                  );
            }
          }
          _flashBidAccepted();
        });

    _auctionSyncSubscription = socketService
        .getEventStream<AuctionStateUpdateEvent>(
          'auctionSync',
          (data) {
            try {
              return AuctionStateUpdateEvent.fromJson(
                Map<String, dynamic>.from(data as Map),
              );
            } catch (_) {
              return const AuctionStateUpdateEvent(
                auctionId: 0,
                products: [],
              );
            }
          },
        )
        .listen(_applyLiveSnapshot);
  }

  Future<void> _checkAccess() async {
    if (widget.isAdmin) {
      setState(() {
        _accessStatus = 'GRANTED';
        _isAccessLoading = false;
      });
      socketActions.startLiveAuction(widget.auctionId, CachedVariables.userId!);
      socketActions.joinAuction(widget.auctionId, CachedVariables.userId!);
      socketActions.requestSync(widget.auctionId);
      return;
    }

    final service = ref.read(auctionAccessServiceProvider);
    final status = await service.checkAccess(
      auctionId: widget.auctionId,
    );

    if (mounted) {
      setState(() {
        _accessStatus = status;
        _isAccessLoading = false;
      });

      if (status == 'GRANTED') {
        socketActions.joinAuction(widget.auctionId, CachedVariables.userId!);
        socketActions.requestSync(widget.auctionId);
      }
    }
  }

  Future<void> _requestAccess() async {
    setState(() {
      _isAccessLoading = true;
    });
    final service = ref.read(auctionAccessServiceProvider);
    final status = await service.requestAccess(
      auctionId: widget.auctionId,
    );
    await AnalyticsService.logAuctionAccessRequested(auctionId: widget.auctionId);
    if (mounted) {
      setState(() {
        _accessStatus = status;
        _isAccessLoading = false;
      });
      if (status == 'PENDING') {
        AppFunctions.showSnackBar(
          context: context,
          message: AppStrings.accessPending.tr(),
          icon: Icons.info_outline,
        );
      }
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LiveRoomVisibility.isViewing.value = false;
    // _cleanupEngine();
    _socketErrorSubscription?.cancel();
    _bidRejectedSubscription?.cancel();
    _bidAcceptedSubscription?.cancel();
    _auctionSyncSubscription?.cancel();
    _swipeHideTimer?.cancel();
    _cancelFailSafeTimer();
    _lotResultTimer?.cancel();
    _audioPlayer.dispose();
    _scrollController.dispose();
    _mainImagePageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      LiveRoomVisibility.isViewing.value = false;
    }
    if (state == AppLifecycleState.resumed) {
      LiveRoomVisibility.isViewing.value = true;
      _rejoinAndSync();
    }
  }

  void _rejoinAndSync() {
    final userId = CachedVariables.userId;
    if (userId == null || _accessStatus != 'GRANTED') return;
    socketActions.joinAuction(widget.auctionId, userId);
    socketActions.requestSync(widget.auctionId);
  }

  void _applyLiveSnapshot(AuctionStateUpdateEvent event) {
    if (!mounted) return;
    if (event.auctionId != 0 && event.auctionId != widget.auctionId) return;
    final price = event.resolvedCurrentPrice;
    setState(() {
      if (price != null) {
        _liveCurrentPrice = price;
        auction.actualPrice = price;
      }
      if (event.expiryDate != null) {
        _liveExpiryDate = event.expiryDate;
        auction.expiryDate = event.expiryDate;
      }
    });
    if (event.expiryDate != null) {
      _scheduleFailSafeTimer(event.expiryDate!);
    }
    for (final product in event.products) {
      for (final bid in product.topBids) {
        ref.read(accumulatedBidsProvider.notifier).addBid(bid);
      }
    }
  }

  void _applyRoomBidUpdate({
    num? currentPrice,
    DateTime? expiryDate,
    int? eventProductId,
  }) {
    if (!mounted) return;
    if (shouldIgnoreLiveBid(
      eventProductId: eventProductId,
      currentProductId: auction.currentProductId,
    )) {
      return;
    }
    if (currentPrice == null && expiryDate == null) return;
    setState(() {
      if (currentPrice != null) {
        _liveCurrentPrice = currentPrice;
        auction.actualPrice = currentPrice;
      }
      if (expiryDate != null) {
        _liveExpiryDate = expiryDate;
        auction.expiryDate = expiryDate;
      }
    });
    if (expiryDate != null) {
      _scheduleFailSafeTimer(expiryDate);
    }
  }

  void _flashBidAccepted() {
    _swipeHideTimer?.cancel();
    setState(() => _suppressSwipe = true);
    _swipeHideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _suppressSwipe = false);
    });
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

  /// Safely plays a sound asset, stopping any in-progress playback first
  /// to prevent IllegalStateException from overlapping prepareAsync calls.
  Future<void> _safePlay(String assetPath, {double volume = 1.0}) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath), volume: volume);
    } catch (e) {
      debugPrint('[AudioPlayer] Error playing $assetPath: $e');
    }
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
      (p) => auction.currentProductId != null
          ? p.id == auction.currentProductId
          : _isSameProduct(p.displayName, auction.currentProduct),
    );

    if (currentIndex == -1 ||
        currentIndex + 1 >= auction.auctionProducts!.length) {
      // nothing to select (could also clear to let user pick any)
      _selectedProduct = null;
    } else {
      _selectedProduct = auction.auctionProducts![currentIndex + 1];
    }
  }

  void _jumpToLiveLot() {
    final products = auction.auctionProducts;
    if (products == null || products.isEmpty) return;
    AuctionProducts? live;
    for (final product in products) {
      if (isCurrentLiveLot(
        productId: product.id,
        productName: product.displayName,
        currentProductId: auction.currentProductId,
        currentProductName: auction.currentProduct,
      )) {
        live = product;
        break;
      }
    }
    if (live == null || live.id == _selectedProduct?.id) return;
    setState(() => _selectedProduct = live);
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
        (element) => auction.currentProductId != null
            ? element.id == auction.currentProductId
            : element.displayName == auction.currentProduct,
        orElse: () => AuctionProducts(),
      );
    }

    if (productToBidOn == null || productToBidOn.id == null) {
      debugPrint(
        'LiveAuctionScreen: Cannot place bid. Product not found: ${auction.currentProduct}',
      );
      if (mounted) {
        AppFunctions.showSnackBar(
          context: context,
          message: AppStrings.lotNotIdentifiedSyncing.tr(),
          icon: Icons.sync,
        );
      }
      // Ask the server for an authoritative snapshot so the next attempt
      // can resolve the product.
      socketActions.requestSync(auction.id ?? widget.auctionId).catchError((_) {});
      return;
    }

    final lastAuctionProduct = ref.read(auctionProductChangeProvider);

    final bool isOpeningBid =
        currentBid == (lastAuctionProduct?.bidPrice ?? auction.bidPrice) &&
        isMinBid;

    _sendBid(productToBidOn.id!, currentBid, isOpeningBid: isOpeningBid);
  }

  /// Emits the bid and surfaces connectivity/emit failures to the user
  /// instead of failing silently.
  Future<void> _sendBid(
    int productId,
    num currentBid, {
    required bool isOpeningBid,
  }) async {
    try {
      await socketActions.placeBid(
        auction.id ?? 0,
        CachedVariables.userId!,
        currentBid.toDouble(),
        productId,
      );
    } catch (e) {
      debugPrint('LiveAuctionScreen: placeBid failed: $e');
      if (!mounted) return;
      final connected = ref.read(socketServiceProvider).isConnected;
      AppFunctions.showSnackBar(
        context: context,
        message: connected
            ? AppStrings.bidSendFailed.tr()
            : AppStrings.notConnectedToLiveRoom.tr(),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Activate rolling-sequence gap detection for this screen.
    ref.watch(auctionGapDetectedProvider);

    ref.listen(auctionStateUpdateProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null) _applyLiveSnapshot(event);
    });

    ref.listen(auctionDetailsProvider(widget.auctionId), (previous, next) {
      final expiry = next.valueOrNull?.expiryDate;
      if (expiry != null && !_isAuctionEnded) {
        _scheduleFailSafeTimer(expiry);
      }
    });

    ref.listen(userCountUpdateProvider, (previous, next) {});

    // Listen for pre-auction start
    ref.listen(auctionPreStartedProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null) {
        setState(() {
          auction = event;
        });
        if (event.liveStartDate != null) {
          _scheduleFailSafeTimer(event.liveStartDate!);
        }
        AppFunctions.showSnackBar(
          context: context,
          message: 'preAuctionPhase'.tr(),
          icon: Icons.info_outline,
        );
      }
    });

    // Listen for Auction Item Ended (Multi-item transition)
    ref.listen(auctionItemEndedProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null) {
        // ── Side effects that must fire immediately (before any rebuild) ───────
        _cancelFailSafeTimer();
        //_wasLiveWhenJoined = true;

        // Record sale/winner for the just-ended product. Sale is isSold only —
        // a winner is attached by the server only when reserve was met.
        final endedProductId =
            event.endedProductId ?? auction.currentProductId;
        final sold = lotWasSold(
          eventIsSold: event.isSold,
          hasWinner: event.winner != null,
        );

        if (endedProductId != null) {
          _productSold[endedProductId] = sold;
          if (sold && event.winner != null) {
            _productWinners[endedProductId] = event.winner!;
          }
          final products = auction.auctionProducts;
          if (products != null) {
            for (final p in products) {
              if (p.id == endedProductId) {
                p.isSold = sold;
                p.isExpired = !sold;
              }
            }
          }
        }

        final didIParticipate =
            (endedProductId != null &&
                _productParticipants.contains(endedProductId)) ||
            (auction.auctionBids?.any(
                  (b) =>
                      b.productId == endedProductId &&
                      b.userId == CachedVariables.userId,
                ) ??
                false);

        final kind = resolveLotResult(
          isEnded: true,
          isLive: false,
          isSold: sold,
          currentUserId: CachedVariables.userId,
          winnerUserId: event.winner?.id,
          userParticipated: didIParticipate,
        );
        _showLotResultBanner(kind);

        if (sold && event.winner != null) {
          if (event.winner!.id == CachedVariables.userId) {
            _safePlay('sounds/win_bid_notification.wav');
            final lang = AppLocaleSync.uiLanguageCode;
            String productName = auction.localizedTitle(lang);
            final match = auction.auctionProducts
                ?.where((p) => p.id == endedProductId)
                .toList();
            if (match != null && match.isNotEmpty) {
              final name = match.first.localizedName(lang);
              if (name.isNotEmpty) productName = name;
            }
            FCMService().showLocalNotification(
              title: AppStrings.youWon.tr(),
              body: '${AppStrings.youWon.tr()} $productName',
            );
          } else if (didIParticipate) {
            _safePlay('sounds/lose_notification.wav');
          }
        }

        if (event.nextItem != null) {
          // ── Compute phase: all lookups / parses happen before setState ───────
          // Keeping CPU work out of setState ensures the callback itself is
          // just plain field assignments — the cheapest possible rebuild.
          final nextItem = event.nextItem!;
          final newBidPrice = num.tryParse(nextItem.bidPrice ?? '0') ?? 0;
          final newExpiry = event.auction.expiryDate;
          final newImageUrl = nextItem.imageUrl;

          // Resolve the product object once; O(n) list scan stays outside setState.
          final AuctionProducts nextProduct =
              (nextItem.id != null &&
                  auction.auctionProducts != null &&
                  auction.auctionProducts!.isNotEmpty)
              ? auction.auctionProducts!.firstWhere(
                  (p) => p.id == nextItem.id,
                  orElse: () => nextItem,
                )
              : nextItem;

          // ── Single commit: only plain field assignments inside setState ──────
          setState(() {
            auction.currentProduct = nextItem.displayName;
            auction.currentProductId = nextItem.id;
            auction.bidPrice = newBidPrice;
            // Live display floor = opening bidPrice. Do not copy reserve/estimate.
            auction.actualPrice = newBidPrice;
            auction.minBidPrice = null;
            if (newImageUrl != null) auction.imageUrl = newImageUrl;
            if (newExpiry != null) auction.expiryDate = newExpiry;
            _isAuctionEnded = false;
            _winnerId = null;
            _winnerName = null;
            _finalPrice = null;
            _selectedProduct = nextProduct;
          });

          // ── Post-setState side effects (no extra rebuild triggered) ──────────
          // addPostFrameCallback is intentionally placed OUTSIDE setState so it
          // does not force a second layout pass within the same frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCurrentItem();
          });
          if (newExpiry != null) {
            _scheduleFailSafeTimer(newExpiry);
          }
        } else {
          // No next item — final product has ended. Compute selection first.
          // _selectNextProduct() reads from auction state synchronously;
          // capture the result so the setState callback is just assignments.
          _selectNextProduct(); // updates _selectedProduct in place
          setState(() {
            _isAuctionEnded = true;
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
          // clear currentProduct so the thumbnail badge is no longer marked LIVE
          auction.currentProduct = null;
          auction.currentProductId = null;
        });
        // _selectNextProduct reads from auction state synchronously;
        // kept outside setState so it doesn't trigger a second pass.
        _selectNextProduct();

        if (event.winnerId == CachedVariables.userId) {
          _safePlay('sounds/win_bid_notification.wav');
          FCMService().showLocalNotification(
            title: AppStrings.youWon.tr(),
            body:
                '${AppStrings.youWon.tr()} ${auction.localizedTitle(AppLocaleSync.uiLanguageCode)}',
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
            _safePlay('sounds/lose_notification.wav');
          }
        }
        // We intentionally no longer pop up a result dialog on the live screen.
        // The bottom bidding controls already reflect the winner/loser state.
      }
    });

    ref.listen(timerExtendedEventProvider, (previous, next) {
      final expiry = next.valueOrNull?.expiryDate;
      if (expiry == null || !mounted) return;
      setState(() {
        auction.expiryDate = expiry;
      });
      _scheduleFailSafeTimer(expiry);
    });

    // Listen for new bids to update timer and price
    ref.listen(newBidEventProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null) {
        if (shouldIgnoreLiveBid(
          eventProductId: event.eventProductId,
          currentProductId: auction.currentProductId,
        )) {
          return;
        }

        final incomingBid = event.newBid;
        if (incomingBid != null &&
            incomingBid.userId != CachedVariables.userId) {
          _safePlay('sounds/higher_bid_notification.wav');
          HapticFeedback.lightImpact();
        }

        final bidProductId = event.eventProductId ?? incomingBid?.productId;
        if (bidProductId != null && auction.auctionProducts != null) {
          final matchingProduct = auction.auctionProducts!.firstWhere(
            (p) => p.id == bidProductId,
            orElse: () => AuctionProducts(),
          );
          if (matchingProduct.id != null && incomingBid != null) {
            matchingProduct.bids ??= [];
            if (!matchingProduct.bids!.any((b) => b.id == incomingBid.id)) {
              matchingProduct.bids!.add(incomingBid);
            }
          }
        }

        if (bidProductId != null &&
            incomingBid?.userId == CachedVariables.userId) {
          _productParticipants.add(bidProductId);
        }

        if (event.auctionBids.isNotEmpty) {
          ref.read(accumulatedBidsProvider.notifier).updateAll(event.auctionBids);
        } else if (incomingBid != null) {
          ref.read(accumulatedBidsProvider.notifier).addBid(incomingBid);
        }

        _applyRoomBidUpdate(
          currentPrice: event.currentPrice ?? incomingBid?.bid,
          expiryDate: event.expiryDate,
          eventProductId: event.eventProductId,
        );
      }
    });

    final auctionValue = ref.watch(auctionDetailsProvider(widget.auctionId));
    auction = auctionValue.valueOrNull ?? AuctionModel(isLiveAuction: true);
    applyHeldLiveFields(
      auction,
      heldPrice: _liveCurrentPrice,
      heldExpiry: _liveExpiryDate,
    );

    // Sync auction pricing fields with the current product's pricing
    if (auction.auctionProducts != null &&
        auction.auctionProducts!.isNotEmpty) {
      // Find the product that matches the current_product name or ID
      final currentProductObj = auction.auctionProducts!.firstWhere(
        (p) => auction.currentProductId != null
            ? p.id == auction.currentProductId
            : p.displayName == auction.currentProduct,
        orElse: () => auction.auctionProducts![0],
      );

      // Public opening only — never copy reserve or estimate onto live auction state.
      if (currentProductObj.productAr != null ||
          currentProductObj.productEn != null) {
        if (currentProductObj.bidPrice != null && _liveCurrentPrice == null) {
          auction.bidPrice =
              num.tryParse(currentProductObj.bidPrice!) ?? auction.bidPrice;
        }
      }
    }

    // Initialize local state if not already set (for initial load)
    // We only set it once when data is first loaded, unless it's already ended locally
    if (auctionValue.hasValue &&
        !_isAuctionEnded &&
        (auction.isExpired == true ||
            auction.isCanceled == true ||
            auction.winningUserId != null)) {
      final endedAuction = auction;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isAuctionEnded) return;
        setState(() {
          _isAuctionEnded = true;
          _winnerId = endedAuction.winningUserId;
          _winnerName = endedAuction.user?.name;
          _finalPrice = endedAuction.actualPrice;
          if (_selectedProduct == null &&
              endedAuction.auctionProducts != null &&
              endedAuction.auctionProducts!.isNotEmpty) {
            _selectedProduct = endedAuction.auctionProducts!.last;
          }
        });
      });
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
          auction.titleAr ?? auction.titleEn ?? 'auctionDetails'.tr(),
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
              return auction.currentProductId != null
                  ? p.id == auction.currentProductId
                  : p.displayName == auction.currentProduct;
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

                    //// Current Product Indicator (New)
                    //if (auction.currentProduct != null && !_isAuctionEnded)
                    //  Container(
                    //    padding: const EdgeInsets.all(12),
                    //    color: Colors.amber.withValues(alpha: 0.1),
                    //    child: Row(
                    //      children: [
                    //        const Icon(
                    //          Icons.label_outline,
                    //          color: Colors.amber,
                    //        ),
                    //        const SizedBox(width: 8),
                    //        Expanded(
                    //          child: Text(
                    //            '${AppStrings.currentItem.tr()}: ${auction.currentProduct}',
                    //            style: Theme.of(context).textTheme.titleMedium
                    //                ?.copyWith(
                    //                  fontWeight: FontWeight.bold,
                    //                  color: Colors.black87,
                    //                ),
                    //          ),
                    //        ),
                    //      ],
                    //    ),
                    //  ),

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
                                auction.currentProductId != null
                                    ? item.id == auction.currentProductId
                                    : item.displayName ==
                                        auction.currentProduct;
                            final bool isSelected =
                                item.id ==
                                (_selectedProduct?.id ??
                                    auction.currentProductId ??
                                    (auction.auctionProducts
                                            ?.firstWhere(
                                              (p) =>
                                                  p.displayName ==
                                                  auction.currentProduct,
                                              orElse: () => AuctionProducts(),
                                            )
                                            .id));

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
                                              (p) =>
                                                  auction.currentProductId !=
                                                          null
                                                      ? p.id ==
                                                          auction
                                                              .currentProductId
                                                      : _isSameProduct(
                                                          p.displayName,
                                                          auction
                                                              .currentProduct,
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

                                        // Past lot — sold badges during live;
                                        // «لم تُبع» only after the whole auction ends.
                                        final kind = visibleLotResult(
                                          _endedLotResult(item),
                                          auctionFullyEnded:
                                              auctionIsFullyEnded(
                                            isAuctionEnded: _isAuctionEnded,
                                            isExpired: auction.isExpired,
                                            isCanceled: auction.isCanceled,
                                          ),
                                        );
                                        if (kind == LotResultKind.none) {
                                          return const SizedBox.shrink();
                                        }
                                        final badgeText =
                                            lotResultStringKey(kind).tr();
                                        final badgeColor = lotResultColor(kind);

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

                    // Main Image -> Title -> Bids -> Thumbnails -> Description
                    Builder(
                      builder: (context) {
                        final imagesToShow = AuctionDetailsHelper.getImagesToShow(auction, activeProduct);
                        final badge = AuctionDetailsHelper.getStatusBadge(
                          auction: auction,
                          activeProduct: activeProduct,
                          isAuctionEnded: _isAuctionEnded,
                          isSoldOverride: activeProduct?.id != null
                              ? _productSold[activeProduct!.id]
                              : null,
                          winnerUserIdOverride: activeProduct?.id != null
                              ? _productWinners[activeProduct!.id]?.id
                              : null,
                          userParticipatedOverride:
                              activeProduct?.id != null &&
                                  _productParticipants
                                      .contains(activeProduct!.id)
                              ? true
                              : null,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuctionMainImageWidget(
                              images: imagesToShow,
                              pageController: _mainImagePageController,
                              onPageChanged: (idx) {
                                setState(() {
                                  _currentMainImageIndex = idx;
                                });
                              },
                              statusLabel: badge.label,
                              statusColor: badge.color,
                              onShare: () {
                                final title = activeProduct?.displayName ??
                                    auction.displayTitle;
                                final url = ItemShareHelper.auctionLotUrl(
                                  auctionId: auction.id ?? widget.auctionId,
                                  lotNumber: activeProduct?.lotNumber,
                                  productId: activeProduct?.id,
                                );
                                showItemShareSheet(
                                  context: context,
                                  title: title,
                                  url: url,
                                );
                              },
                              onWatch: activeProduct?.id == null
                                  ? null
                                  : () {
                                      ref
                                          .read(
                                            favoritesControllerProvider
                                                .notifier,
                                          )
                                          .toggleWatchLot(activeProduct!);
                                    },
                              isWatched: activeProduct?.id != null &&
                                  ref
                                      .watch(favoritesControllerProvider)
                                      .maybeWhen(
                                        data: (d) => d.watchedLotIds
                                            .contains(activeProduct!.id),
                                        orElse: () => false,
                                      ),
                            ),
                            AuctionItemTitleWidget(
                              auction: auction,
                              activeProduct: activeProduct,
                            ),
                            AuctionBidsHistoryWidget(
                              initialBids: auction.auctionBids ?? [],
                              productId: activeProduct?.id,
                            ),
                            AuctionThumbnailsWidget(
                              images: imagesToShow,
                              currentIndex: _currentMainImageIndex,
                              onTap: (idx) {
                                _mainImagePageController.animateToPage(
                                  idx,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                            AuctionItemDescriptionWidget(
                              auction: auction,
                              activeProduct: activeProduct,
                            ),
                          ],
                        );
                      },
                    ),

                    gapH24,
                  ],
                ),
              ),
            ),
            if (_lotResult != null && _lotResult != LotResultKind.none)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: LotResultBanner(
                  kind: _lotResult!,
                  onDismiss: () {
                    _lotResultTimer?.cancel();
                    setState(() => _lotResult = null);
                  },
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
                  !isCurrentLiveLot(
                    productId: _selectedProduct?.id,
                    productName: _selectedProduct?.displayName,
                    currentProductId: auction.currentProductId,
                    currentProductName: auction.currentProduct,
                  ),
              onGoToLiveLot: _jumpToLiveLot,
              selectedProduct: _selectedProduct,
              isOwner: auction.userId == CachedVariables.userId,
              winnerId: _winnerId,
              winnerName: _winnerName,
              finalPrice: _finalPrice,
              suppressSwipe: _suppressSwipe,
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
      case 'PROFILE_PENDING':
        icon = Icons.hourglass_top_rounded;
        color = Colors.orange;
        title = AppStrings.profileApprovalPending.tr();
        message = AppStrings.profileApprovalPendingDescription.tr();
        break;
      case 'NICKNAME_REQUIRED':
        icon = Icons.badge_outlined;
        color = Colors.orange;
        title = AppStrings.nicknameRequiredForAuction.tr();
        message = AppStrings.nicknameRequiredForAuctionDescription.tr();
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

  void _showLotResultBanner(LotResultKind kind) {
    final visible = visibleLotResult(
      kind,
      auctionFullyEnded: auctionIsFullyEnded(
        isAuctionEnded: _isAuctionEnded,
        isExpired: auction.isExpired,
        isCanceled: auction.isCanceled,
      ),
    );
    if (visible == LotResultKind.none) return;
    _lotResultTimer?.cancel();
    setState(() => _lotResult = visible);
    _lotResultTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _lotResult = null);
    });
  }

  LotResultKind _endedLotResult(AuctionProducts item) {
    final liveSold = item.id != null ? _productSold[item.id] : null;
    final liveWinner = item.id != null ? _productWinners[item.id] : null;
    final isSold = lotWasSold(
      productIsSold: item.isSold,
      eventIsSold: liveSold,
      hasWinner: liveWinner != null,
    );

    int? winnerId = liveWinner?.id;
    if (winnerId == null && isSold) {
      final productBids = item.bids ?? [];
      if (productBids.isNotEmpty) {
        final sorted = [...productBids]
          ..sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0));
        winnerId = sorted.first.userId;
      }
    }

    final currentUserId = CachedVariables.userId;
    final didParticipate =
        (item.id != null && _productParticipants.contains(item.id)) ||
        (item.bids?.any((b) => b.userId == currentUserId) ?? false);

    return resolveLotResult(
      isEnded: true,
      isLive: false,
      isSold: isSold,
      currentUserId: currentUserId,
      winnerUserId: winnerId,
      userParticipated: didParticipate,
    );
  }

  void _scrollToCurrentItem() {
    if (!mounted ||
        auction.auctionProducts == null ||
        auction.auctionProducts!.isEmpty) {
      return;
    }

    final index = auction.auctionProducts!.indexWhere(
      (p) => auction.currentProductId != null
          ? p.id == auction.currentProductId
          : p.displayName == auction.currentProduct,
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
    final now = DateTime.now();
    // Schedule for expiry + 2 seconds
    final difference = expiry.difference(now) + const Duration(seconds: 2);

    if (difference.isNegative) {
      if (_failSafeFiredForExpiry != null &&
          _failSafeFiredForExpiry!.isAtSameMomentAs(expiry)) {
        return;
      }
      _failSafeFiredForExpiry = expiry;
      _cancelFailSafeTimer();
      _triggerFailSafe();
      return;
    }

    if (_scheduledFailSafeExpiry != null &&
        _scheduledFailSafeExpiry!.isAtSameMomentAs(expiry) &&
        _failSafeTimer != null &&
        _failSafeTimer!.isActive) {
      return;
    }

    _cancelFailSafeTimer();
    _failSafeFiredForExpiry = null;
    _scheduledFailSafeExpiry = expiry;
    _failSafeTimer = Timer(difference, () {
      _failSafeFiredForExpiry = expiry;
      _triggerFailSafe();
    });
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
