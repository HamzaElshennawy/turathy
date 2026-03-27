// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/utils/auction_details_helper.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_main_image_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_item_title_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_thumbnails_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_item_description_widget.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/live_auction_screen.dart';
import 'package:turathy/src/features/notifications/presentation/notifications_screen.dart';
import 'package:turathy/src/features/auctions/data/auction_access_service.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../authintication/presentation/sign_in_screen.dart';
import '../../domain/auction_model.dart';
import '../../data/auctions_repository.dart';
import 'widgets/auction_images_slider_widget.dart';
import 'widgets/auction_bids_history_widget.dart';
import 'package:turathy/src/core/helper/socket/socket_providers.dart';
import 'package:turathy/src/core/helper/socket/socket_models.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuctionScreen extends ConsumerStatefulWidget {
  final AuctionModel auction;

  const AuctionScreen(this.auction, {super.key});

  @override
  ConsumerState<AuctionScreen> createState() => _AuctionScreenState();
}

class _BottomSheetContentWrapper extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    PageController controller,
    int currentIndex,
    ValueChanged<int> onPageChanged,
  ) builder;

  const _BottomSheetContentWrapper({required this.builder});

  @override
  State<_BottomSheetContentWrapper> createState() =>
      _BottomSheetContentWrapperState();
}

class _BottomSheetContentWrapperState extends State<_BottomSheetContentWrapper> {
  late PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller, _currentIndex, (idx) {
      if (mounted) setState(() => _currentIndex = idx);
    });
  }
}

enum ProductSortOption { none, priceLowToHigh, priceHighToLow }

class _AuctionScreenState extends ConsumerState<AuctionScreen> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isGridView = false; // State for toggling view
  List<AuctionProducts> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  // Filtering & Sorting State
  ProductSortOption _currentSortOption = ProductSortOption.none;
  bool _filterBiddedOnly = false;

  String? _accessStatus;
  bool _isAccessLoading = true;
  bool _isLoadingDetails = false;
  late AuctionModel _currentAuction;

  // --- Socket / Live Bid Tracking ---
  // Maps productId → the current highest AuctionBid for that product
  final Map<int, AuctionBid> _highestBids = {};
  // Set of productIds where the current user has placed at least one bid
  final Set<int> _userBidProductIds = {};
  StreamSubscription? _stateUpdateSubscription;
  StreamSubscription? _bidSubscription;
  StreamSubscription? _auctionStartedSubscription;
  StreamSubscription? _itemEndedSubscription;
  StreamSubscription? _socketErrorSubscription;
  StreamSubscription? _bidRejectedSubscription;
  SocketActions? _socketActions;

  /// Whether the user can open item bottom sheets (only GRANTED or owner)
  bool get _canOpenItemBottomSheet =>
      _accessStatus == 'GRANTED' ||
      _currentAuction.userId == CachedVariables.userId;

  /// Whether the auction has entered at least the pre-auction phase (now >= startDate)
  bool get _hasPreAuctionStarted {
    if (_currentAuction.startDate == null) return false;
    return DateTime.now().isAfter(_currentAuction.startDate!);
  }

  @override
  void initState() {
    super.initState();
    _currentAuction = widget.auction;
    _filteredProducts = _currentAuction.auctionProducts ?? [];
    _calculateTimeLeft();
    _startTimer();
    _checkAccess();
    _fetchAuctionDetails();
    // Connect socket and join the auction room so we receive live bid events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListeners();
    });
  }

  void _setupSocketListeners() {
    if (!mounted) return;
    final socketService = ref.read(socketServiceProvider);
    _socketActions = ref.read(socketActionsProvider);
    final userId = CachedVariables.userId;
    final auctionId = _currentAuction.id;
    if (userId == null || auctionId == null) return;

    // Ensure socket is connected and join the auction room
    _socketActions?.joinAuction(auctionId, userId);

    // ── STATE BROADCAST LISTENER ──
    // Passively listen to the 2-second snapshot blasts from the server
    _stateUpdateSubscription = socketService
        .getEventStream<AuctionStateUpdateEvent>(
          'auctionStateUpdate',
          (data) =>
              AuctionStateUpdateEvent.fromJson(data as Map<String, dynamic>),
        )
        .listen((event) {
          if (!mounted || event.auctionId != auctionId) return;

          if (kDebugMode) {
            print(
              '[AuctionStateUpdate] Received broadcast payload: ${event.toJson()}',
            );
          }

          setState(() {
            // 1. Instantly snap the timer/expiry to the server's truth
            if (event.expiryDate != null) {
              _currentAuction.expiryDate = event.expiryDate;
            }

            // 2. Snap the active product ID
            if (event.currentProductId != null) {
              _currentAuction.currentProductId = event.currentProductId;
            }

            // 3. Snap the highest bid local cache for UI rendering
            for (final product in event.products) {
              final productId = product.id;
              if (productId == null) continue;

              for (final bid in product.topBids) {
                final existing = _highestBids[productId];
                if (existing == null || (bid.bid ?? 0) >= (existing.bid ?? 0)) {
                  _highestBids[productId] = bid;
                }
              }
            }
          });
        });

    // Listen for new bids and track highest bid per product
    _bidSubscription = socketService
        .getEventStream<BidPlacedEvent>(
          'newBid',
          (data) => BidPlacedEvent.fromJson(data as Map<String, dynamic>),
        )
        .listen((event) {
          if (!mounted) return;
          final bid = event.newBid;
          final productId = bid.productId;
          if (productId == null) return;

          setState(() {
            // Track that THIS user bid on this product
            if (bid.userId == userId) {
              _userBidProductIds.add(productId);
            }

            // Update highest bid for this product
            final existing = _highestBids[productId];
            if (existing == null || (bid.bid ?? 0) >= (existing.bid ?? 0)) {
              _highestBids[productId] = bid;
            }
          });
        });

    // Listen for auction started / pre-started events → re-check access
    _auctionStartedSubscription = socketService
        .getEventStream<AuctionModel>(
          'auctionStarted',
          (data) => AuctionModel.fromJson(data as Map<String, dynamic>),
        )
        .listen((event) {
          if (!mounted) return;
          if (event.id == auctionId) {
            _checkAccess();
          }
        });

    // Listen for item ended events → update current product highlight
    _itemEndedSubscription = socketService
        .getEventStream<AuctionItemEndedEvent>(
          'auctionItemEnded',
          (data) =>
              AuctionItemEndedEvent.fromJson(data as Map<String, dynamic>),
        )
        .listen((event) {
          if (!mounted) return;
          if (event.auction.id == auctionId) {
            setState(() {
              _currentAuction.currentProduct = event.auction.currentProduct;
              _currentAuction.currentProductId = event.auction.currentProductId;
              _currentAuction.expiryDate = event.auction.expiryDate;
            });
          }
        });

    // Listen to socket errors (e.g., "Max bid limit exceeded" or out of sync)
    _socketErrorSubscription = socketService
        .getEventStream<dynamic>('error', (data) => data)
        .listen((data) {
          if (mounted && data != null) {
            final message = data['message'] ?? data.toString();

            if (message.toString().toLowerCase().contains(
              'max bid limit exceeded',
            )) {
              _showFloatingToast(
                AppStrings.bidLimitExceeded.tr(),
                icon: Icons.block,
                color: Colors.red,
              );
            }
            // bid rejected
            else if (message.toString().contains("bidRejected")) {
              if (kDebugMode) {
                _showFloatingToast(
                  'Bid Rejected $message',
                  icon: Icons.price_change_outlined,
                  color: Colors.deepOrange,
                );
              }
              //_fetchAuctionDetails();
            } else {
              // Other non-bid errors: show message and refresh
              _showFloatingToast(
                message.toString(),
                icon: Icons.error_outline,
                color: Colors.red,
              );
              _fetchAuctionDetails();
            }
          }
        });

    // Listen for bid rejections caused by stale price (out-of-sync).
    // The server sends the real current price so we can update _highestBids
    // instantly, without an HTTP fetch.
    _bidRejectedSubscription = socketService
        .getEventStream<dynamic>('bidRejected', (data) => data)
        .listen((data) {
          if (!mounted || data == null) return;
          final serverPrice = data['currentPrice'] as num?;
          final minBid = data['minimumBid'] as num?;
          final productId = data['productId'] as int?;

          if (serverPrice != null && productId != null) {
            setState(() {
              // Build a synthetic AuctionBid to update the highest-bid map
              final existing = _highestBids[productId];
              if (existing != null) {
                _highestBids[productId] = AuctionBid(
                  id: existing.id,
                  userId: existing.userId,
                  bid: serverPrice,
                  productId: productId,
                  auctionId: existing.auctionId,
                  isActive: existing.isActive,
                  user: existing.user,
                );
              }

              // If the rejected product is the current live item, also update
              // the auction-level price fields so the open bottom sheet (which
              // reads from _currentAuction) immediately shows the correct price.
              if (productId == _currentAuction.currentProductId ||
                  (_currentAuction.auctionProducts?.any(
                        (p) =>
                            p.id == productId &&
                            p.displayName == _currentAuction.currentProduct,
                      ) ??
                      false)) {
                _currentAuction.actualPrice = serverPrice;
                if (minBid != null) {
                  _currentAuction.minBidPrice = minBid;
                }
              }
            });
          }

          final hint = minBid != null ? ' (min: $minBid)' : '';
          _showFloatingToast(
            '${'priceUpdatedRetry'.tr()}$hint',
            icon: Icons.sync_problem_outlined,
            color: Colors.orange,
          );
        });
  }

  /// Shows a polished floating toast that renders on top of every layer
  /// (including open bottom sheets) by inserting into the root [Overlay].
  void _showFloatingToast(
    String message, {
    IconData icon = Icons.info_outline,
    Color color = Colors.red,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    // Use the navigator overlay so it sits above everything, including sheets.
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    final animController = AnimationController(
      vsync: Navigator.of(context, rootNavigator: true),
      duration: const Duration(milliseconds: 300),
    );
    final fadeAnim = CurvedAnimation(
      parent: animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    final slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animController, curve: Curves.easeOut));

    bool removed = false;
    void dismiss() {
      if (removed) return;
      animController.reverse().then((_) {
        if (!removed) {
          entry.remove();
          removed = true;
          animController.dispose();
        }
      });
    }

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 16,
        right: 16,
        child: SlideTransition(
          position: slideAnim,
          child: FadeTransition(
            opacity: fadeAnim,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: dismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.18),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: color.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: dismiss,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    animController.forward();
    Future.delayed(duration, dismiss);
  }

  Future<void> _fetchAuctionDetails() async {
    if (_currentAuction.id == null) return;
    setState(() {
      _isLoadingDetails = true;
    });
    try {
      final repository = ref.read(productsRepositoryProvider);
      final fullAuction = await repository.getAuctionByID(_currentAuction.id!);
      if (mounted) {
        setState(() {
          _currentAuction = fullAuction;
          // Seed highest bids from loaded bid history
          _seedHighestBidsFromAuction(fullAuction);
          // Re-apply filters with the new data
          _applyFiltersAndSort();
        });
        _calculateTimeLeft();
      }
    } catch (e) {
      debugPrint("Error fetching full auction details: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  /// Pre-populate _highestBids and _userBidProductIds from auction bid history
  void _seedHighestBidsFromAuction(AuctionModel auction) {
    final userId = CachedVariables.userId;
    final products = auction.auctionProducts ?? [];
    for (final product in products) {
      final bids = product.bids ?? [];
      if (bids.isEmpty) continue;
      // Find the highest active bid for this product (fallback to highest any if none active)
      final sorted = [...bids]
        ..sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0));

      final activeSorted = [...bids.where((b) => b.isActive == true)]
        ..sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0));

      final highestActive = activeSorted.isNotEmpty
          ? activeSorted.first
          : sorted.first;

      if (product.id != null) {
        _highestBids[product.id!] = highestActive;
        // If current user has a bid on this product, track it
        if (userId != null && bids.any((b) => b.userId == userId)) {
          _userBidProductIds.add(product.id!);
        }
      }
    }
  }

  Future<void> _checkAccess() async {
    final service = ref.read(auctionAccessServiceProvider);
    final status = await service.checkAccess(
      auctionId: _currentAuction.id ?? 0,
      auctionOwnerId: _currentAuction.userId,
    );
    if (mounted) {
      setState(() {
        _accessStatus = status;
        _isAccessLoading = false;
      });
    }
  }

  Future<void> _requestAccess() async {
    if (CachedVariables.userId == null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => SignInScreen()));
      return;
    }

    setState(() {
      _isAccessLoading = true;
    });
    final service = ref.read(auctionAccessServiceProvider);
    final status = await service.requestAccess(
      auctionId: _currentAuction.id ?? 0,
    );
    if (mounted) {
      setState(() {
        _accessStatus = status;
        _isAccessLoading = false;
      });
      if (status == 'PENDING') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.accessPending.tr()),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(AuctionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.auction.auctionProducts != oldWidget.auction.auctionProducts) {
      setState(() {
        _applyFiltersAndSort();
      });
    }
  }

  @override
  void dispose() {
    _stateUpdateSubscription?.cancel();
    _timer?.cancel();
    _searchController.dispose();
    _bidSubscription?.cancel();
    _auctionStartedSubscription?.cancel();
    _itemEndedSubscription?.cancel();
    _socketErrorSubscription?.cancel();
    _bidRejectedSubscription?.cancel();
    // Leave the auction socket room
    final userId = CachedVariables.userId;
    final auctionId = _currentAuction.id;
    if (userId != null && auctionId != null) {
      _socketActions?.leaveAuction(auctionId, userId);
    }
    super.dispose();
  }

  void _filterProducts(String query) {
    _applyFiltersAndSort(query: query);
  }

  void _applyFiltersAndSort({String? query}) {
    setState(() {
      final String searchQuery = (query ?? _searchController.text)
          .toLowerCase();
      List<AuctionProducts> results = _currentAuction.auctionProducts ?? [];

      // 1. Text Search Filter
      if (searchQuery.isNotEmpty) {
        results = results.where((product) {
          return product.displayName.toLowerCase().contains(searchQuery);
        }).toList();
      }

      // 2. Bidded Items Filter
      if (_filterBiddedOnly) {
        results = results.where((product) {
          return product.id != null && _userBidProductIds.contains(product.id!);
        }).toList();
      }

      // 3. Sorting Helper
      num getProductPrice(AuctionProducts p) {
        final highestBid = _highestBids[p.id]?.bid;
        if (highestBid != null) return highestBid;
        return num.tryParse(p.minBidPrice ?? '0') ?? 0;
      }

      // 4. Sorting
      // IMPORTANT: Use a clone of the list for sorting to preserve the original order
      // in _currentAuction.auctionProducts for persistent item numbering.
      List<AuctionProducts> processedResults = List.from(results);

      if (_currentSortOption == ProductSortOption.priceLowToHigh) {
        processedResults.sort(
          (a, b) => getProductPrice(a).compareTo(getProductPrice(b)),
        );
      } else if (_currentSortOption == ProductSortOption.priceHighToLow) {
        processedResults.sort(
          (a, b) => getProductPrice(b).compareTo(getProductPrice(a)),
        );
      } else {
        // Default sort by ID to maintain stability
        processedResults.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      }

      _filteredProducts = processedResults;
    });
  }

  void _calculateTimeLeft() {
    if (widget.auction.startDate != null) {
      final startDate = widget.auction.startDate!;
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        setState(() {
          _timeLeft = startDate.difference(now);
        });
      } else {
        setState(() {
          _timeLeft = Duration.zero;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat(
      'd MMMM, h:mm a',
    ).format(date); // Example: 14 December, 10:30 AM
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    ui.TextDirection? textDirection,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            textDirection: textDirection ?? ui.TextDirection.ltr,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Returns a badge widget showing the user's bid status for a product,
  /// or null if the user hasn't bid on this product.
  /// Only shown once the auction has entered at least the pre-auction phase.
  Widget? _buildBidStatusBadge(int? productId) {
    if (productId == null) return null;
    // Don't show any badge before the auction has started at all
    if (!_hasPreAuctionStarted) return null;
    if (!_userBidProductIds.contains(productId)) return null;

    final highestBid = _highestBids[productId];
    final isHighest = highestBid?.userId == CachedVariables.userId;

    // Determine if this specific item has ended
    bool isProductEnded = false;
    // Whole auction is marked expired/canceled or ended
    if (_currentAuction.isExpired == true ||
        _currentAuction.isCanceled == true) {
      isProductEnded = true;
    } else if (_currentAuction.expiryDate != null &&
        _currentAuction.expiryDate!.isBefore(DateTime.now())) {
      isProductEnded = true;
    } else if (_currentAuction.currentProduct != null &&
        _currentAuction.auctionProducts != null) {
      // In a live auction, if this item comes BEFORE the current item, it has ended
      final currentIndex = _currentAuction.auctionProducts!.indexWhere(
        (p) =>
            p.displayName == _currentAuction.currentProduct ||
            p.id == _currentAuction.currentProductId,
      );
      final thisIndex = _currentAuction.auctionProducts!.indexWhere(
        (p) => p.id == productId,
      );
      if (currentIndex != -1 && thisIndex != -1 && thisIndex < currentIndex) {
        isProductEnded = true;
      }
    } else if (_currentAuction.currentProduct == null &&
        _currentAuction.isPreAuction == false &&
        _timeLeft == Duration.zero) {
      // Auction seems to have ended completely
      isProductEnded = true;
    }

    // Need to also check if we have an inactive highest bid
    bool isHighestInactive = false;
    final productBids =
        _currentAuction.auctionProducts
            ?.firstWhere(
              (p) => p.id == productId,
              orElse: () => AuctionProducts(),
            )
            .bids ??
        [];
    if (productBids.isNotEmpty) {
      final sorted = [...productBids]
        ..sort((a, b) => (b.bid ?? 0).compareTo(a.bid ?? 0));
      if (sorted.first.userId == CachedVariables.userId && !isHighest) {
        final currentHighestSocketBid = _highestBids[productId]?.bid ?? 0;
        if ((sorted.first.bid ?? 0) > currentHighestSocketBid) {
          isHighestInactive = true;
        }
      }
    }

    String badgeText;
    IconData badgeIcon;
    Color badgeColor;

    if (isProductEnded) {
      badgeText = isHighest ? AppStrings.youWon.tr() : AppStrings.youLost.tr();
      badgeIcon = isHighest ? Icons.emoji_events : Icons.close;
      badgeColor = isHighest ? Colors.green.shade600 : Colors.red.shade600;
    } else {
      if (isHighest) {
        badgeText = AppStrings.highestBid.tr();
        badgeIcon = Icons.emoji_events;
        badgeColor = Colors.green.shade600;
      } else if (isHighestInactive) {
        badgeText = 'Max bid is registered'; // Typically from AppStrings
        badgeIcon = Icons.check_circle_outline;
        badgeColor = Colors.orange.shade600;
      } else {
        badgeText = AppStrings.outbid.tr();
        badgeIcon = Icons.arrow_upward;
        badgeColor = Colors.red.shade600;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// True when screen width is wide enough to use the side-by-side tablet layout.
  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  Widget _buildAccessButton(BuildContext context) {
    bool isUpcoming = _timeLeft > Duration.zero;
    bool isGranted = _accessStatus == 'GRANTED';
    bool isPending = _accessStatus == 'PENDING';
    bool isDenied = _accessStatus == 'DENIED';
    bool isOwner = _currentAuction.userId == CachedVariables.userId;

    bool isAuctionEnded = false;
    if (_currentAuction.isExpired == true ||
        _currentAuction.isCanceled == true) {
      isAuctionEnded = true;
    }
    //else if (_currentAuction.expiryDate != null &&
    //    _currentAuction.expiryDate!.isBefore(DateTime.now())) {
    //  isAuctionEnded = true;
    //}
    else if (_currentAuction.currentProduct == null &&
        _currentAuction.isPreAuction == false &&
        _timeLeft == Duration.zero) {
      isAuctionEnded = true;
    }

    VoidCallback? onPressed;
    String buttonText = '';
    Color? buttonColor;
    Color? buttonTextColor;
    bool isPreAuction = _currentAuction.isPreAuction;

    if (isAuctionEnded) {
      buttonText = AppStrings.ended.tr();
      buttonColor = Colors.grey;
      onPressed = null;
    } else if (isOwner || isGranted) {
      if (isUpcoming || isPreAuction) {
        // User already has access; wait for the live auction to actually start
        return const SizedBox.shrink();
      } else {
        buttonText = AppStrings.joinNow.tr();
        buttonColor = Theme.of(context).primaryColor;
        buttonTextColor = Colors.red;
        onPressed = () {
          if (CachedVariables.userId == null) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => SignInScreen()));
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LiveAuctionScreen(
                auctionId: _currentAuction.id ?? 0,
                isAdmin: isOwner,
              ),
            ),
          );
        };
      }
    } else if (isPending) {
      buttonText = AppStrings.accessPending.tr();
      buttonColor = Colors.orange;
      onPressed = null;
    } else if (isDenied) {
      buttonText = AppStrings.accessDenied.tr();
      buttonColor = Colors.red;
      onPressed = null;
    } else {
      // REQUIRED or ERROR
      buttonText = AppStrings.requestAccess.tr();
      buttonColor = Theme.of(context).primaryColor;
      onPressed = _requestAccess;
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: buttonColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: buttonColor,
      ),
      child: Text(
        buttonText,
        style: TextStyle(fontWeight: FontWeight.bold, color: buttonTextColor),
      ),
    );
  }

  void _showItemBottomSheet(
    BuildContext context,
    AuctionProducts product,
    int itemIndex,
  ) {
    final bool isTabletSheet = MediaQuery.of(context).size.width >= 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // On tablets constrain the sheet width so it doesn't feel stretched.
      constraints: isTabletSheet
          ? BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.95)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _BottomSheetContentWrapper(
          builder: (wrapperContext, pageController, currentIndex, onPageChanged) {
            return Consumer(
              builder: (sheetContext, ref, child) {
            // Watch new bids AND bid rejections so the sheet always
            // reflects the latest server-authoritative price.

            final lastBid = ref.watch(currentBidStateProvider);

            final lastRejection = ref.watch(bidRejectedProvider);
            // Watch the 2-second state broadcast to force the modal to re-render
            // with the latest timer/price that the parent widget just saved.

            final stateUpdate = ref.watch(auctionStateUpdateProvider);

            // Merge real-time bids into a combined list for this product
            final initialBids =
                product.bids ?? _currentAuction.auctionBids ?? [];

            // ── Build the bidding-controls widget once so it can be placed
            // either at the bottom of a column (phone) or in the right panel
            // (tablet) without duplicating the callback logic.
            Widget buildBiddingControls(BuildContext builderContext) {
              if (!_hasPreAuctionStarted) return const SizedBox.shrink();

              final bool isInLivePhase =
                  _currentAuction.currentProductId != null ||
                  (_currentAuction.currentProduct != null &&
                      !_currentAuction.isPreAuction);

              if (isInLivePhase && _currentAuction.auctionProducts != null) {
                final products = _currentAuction.auctionProducts!;
                final currentIndex = products.indexWhere(
                  (p) =>
                      p.id == _currentAuction.currentProductId ||
                      p.displayName == _currentAuction.currentProduct,
                );
                final thisIndex = products.indexWhere(
                  (p) => p.id == product.id,
                );

                // Item has ENDED
                if (currentIndex != -1 &&
                    thisIndex != -1 &&
                    thisIndex < currentIndex) {
                  final highestBid = _highestBids[product.id];
                  final soldPrice = highestBid?.bid?.toStringAsFixed(0) ?? '—';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.gavel,
                          color: Colors.grey.shade600,
                          size: 28,
                        ),
                        gapH8,
                        Text(
                          '${AppStrings.itemEndedSoldFor.tr()} $soldPrice ${AppStrings.currency.tr()}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Item is COMING SOON
                if (currentIndex != -1 &&
                    thisIndex != -1 &&
                    thisIndex > currentIndex) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                        gapH8,
                        Text(
                          AppStrings.comingSoon.tr(),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }

              // Current item OR pre-auction → show bidding controls
              return AuctionBiddingControlsWidget(
                auction: _currentAuction,
                selectedProduct: product,
                showOnlyMaxBid: true,
                onPlaceBid: (qty, price, productId) {
                  if (productId != null) {
                    final socketActions = ref.read(socketActionsProvider);
                    socketActions.placeBid(
                      _currentAuction.id ?? 0,
                      CachedVariables.userId ?? 0,
                      price.toDouble(),
                      productId,
                    );
                    final overlay = Overlay.of(sheetContext);
                    late OverlayEntry overlayEntry;
                    bool isRemoved = false;
                    overlayEntry = OverlayEntry(
                      builder: (context) => Positioned(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 100,
                        left: 16.0,
                        right: 16.0,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppStrings.bidPlacedSuccessfully.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    overlay.insert(overlayEntry);
                    Future.delayed(const Duration(seconds: 3), () {
                      if (!isRemoved) {
                        overlayEntry.remove();
                        isRemoved = true;
                      }
                    });
                  }
                },
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.9,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header row (shared by both layouts) ──────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppStrings.itemNumber.tr()}: $itemIndex',
                            style: Theme.of(sheetContext).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      gapH16,

                      // ── Body: two-column on tablet, single-column on phone ──
                      Flexible(
                        child: isTabletSheet
                            // ── Tablet: side-by-side ─────────────────────────
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: item image + info table
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Builder(
                                        builder: (context) {
                                          final imagesToShow = AuctionDetailsHelper.getImagesToShow(_currentAuction, product);
                                          final badge = AuctionDetailsHelper.getStatusBadge(
                                            auction: _currentAuction,
                                            activeProduct: product,
                                            isAuctionEnded: false, // from original code
                                          );
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              AuctionMainImageWidget(
                                                images: imagesToShow,
                                                pageController: pageController,
                                                onPageChanged: onPageChanged,
                                                statusLabel: badge.label,
                                                statusColor: badge.color,
                                              ),
                                              AuctionItemTitleWidget(
                                                auction: _currentAuction,
                                                activeProduct: product,
                                              ),
                                              AuctionThumbnailsWidget(
                                                images: imagesToShow,
                                                currentIndex: currentIndex,
                                                onTap: (idx) => pageController.animateToPage(
                                                  idx,
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                ),
                                              ),
                                              AuctionItemDescriptionWidget(
                                                auction: _currentAuction,
                                                activeProduct: product,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  VerticalDivider(
                                    width: 16,
                                    color: Colors.grey.shade200,
                                  ),
                                  // Right: bid history + bidding controls
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Flexible(
                                          child: SingleChildScrollView(
                                            child: AuctionBidsHistoryWidget(
                                              initialBids: initialBids,
                                              productId: product.id,
                                            ),
                                          ),
                                        ),
                                        gapH16,
                                        Builder(builder: buildBiddingControls),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            // ── Phone: original stacked layout ──────────────
                            : SingleChildScrollView(
                                child: Builder(
                                  builder: (context) {
                                    final imagesToShow = AuctionDetailsHelper.getImagesToShow(_currentAuction, product);
                                    final badge = AuctionDetailsHelper.getStatusBadge(
                                      auction: _currentAuction,
                                      activeProduct: product,
                                      isAuctionEnded: false,
                                    );
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        AuctionMainImageWidget(
                                          images: imagesToShow,
                                          pageController: pageController,
                                          onPageChanged: onPageChanged,
                                          statusLabel: badge.label,
                                          statusColor: badge.color,
                                        ),
                                        AuctionItemTitleWidget(
                                          auction: _currentAuction,
                                          activeProduct: product,
                                        ),
                                        AuctionBidsHistoryWidget(
                                          initialBids: initialBids,
                                          productId: product.id,
                                        ),
                                        AuctionThumbnailsWidget(
                                          images: imagesToShow,
                                          currentIndex: currentIndex,
                                          onTap: (idx) => pageController.animateToPage(
                                            idx,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          ),
                                        ),
                                        AuctionItemDescriptionWidget(
                                          auction: _currentAuction,
                                          activeProduct: product,
                                        ),
                                        if (_hasPreAuctionStarted) ...[
                                          gapH16,
                                          Builder(builder: buildBiddingControls),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  },
);
}

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.filterOptions.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  gapH8,
                  Text(
                    AppStrings.filters.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CheckboxListTile(
                    title: Text(AppStrings.itemsIBiddedOn.tr()),
                    value: _filterBiddedOnly,
                    onChanged: (value) {
                      setBottomSheetState(() {
                        _filterBiddedOnly = value ?? false;
                      });
                      setState(() {});
                      _applyFiltersAndSort();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  gapH16,
                  Text(
                    AppStrings.price.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RadioListTile<ProductSortOption>(
                    title: Text(AppStrings.defaultSort.tr()),
                    value: ProductSortOption.none,
                    groupValue: _currentSortOption,
                    onChanged: (value) {
                      setBottomSheetState(() {
                        _currentSortOption = value!;
                      });
                      setState(() {});
                      _applyFiltersAndSort();
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<ProductSortOption>(
                    title: Text(AppStrings.sortByPriceLowToHigh.tr()),
                    value: ProductSortOption.priceLowToHigh,
                    groupValue: _currentSortOption,
                    onChanged: (value) {
                      setBottomSheetState(() {
                        _currentSortOption = value!;
                      });
                      setState(() {});
                      _applyFiltersAndSort();
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<ProductSortOption>(
                    title: Text(AppStrings.sortByPriceHighToLow.tr()),
                    value: ProductSortOption.priceHighToLow,
                    groupValue: _currentSortOption,
                    onChanged: (value) {
                      setBottomSheetState(() {
                        _currentSortOption = value!;
                      });
                      setState(() {});
                      _applyFiltersAndSort();
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  gapH24,
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(AppStrings.applyFilters.tr()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep socket bids alive while the parent screen is open
    ref.watch(accumulatedBidsProvider);
    ref.watch(latestExpiryDateStateProvider);
    // Activate rolling-sequence gap detection for this screen.
    ref.watch(auctionGapDetectedProvider);

    // Re-evaluate access when the auction starts (e.g. admin approves access)
    ref.listen(auctionStartedProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null && event.id == _currentAuction.id) {
        final wasNotGranted = _accessStatus != 'GRANTED';
        _checkAccess().then((_) {
          if (mounted && wasNotGranted && _accessStatus == 'GRANTED') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.accessGranted.tr()),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    });

    // Also listen for pre-auction started event
    ref.listen(auctionPreStartedProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event != null && event.id == _currentAuction.id) {
        _checkAccess();
      }
    });

    if (_isLoadingDetails) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Turathy'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turathy'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkAccess,
          child: _isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
        ),
      ),
    );
  }

  /// Phone layout: single scrollable column (original behaviour).
  Widget _buildPhoneLayout() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildDetailsPanel(), _buildItemsPanel()],
      ),
    );
  }

  /// Tablet layout: left panel = auction details, right panel = items list.
  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel — auction info & access button
        Flexible(
          flex: 5,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _buildDetailsPanel(),
          ),
        ),
        VerticalDivider(width: 1, color: Colors.grey.shade200),
        // Right panel — search/filter + items
        Flexible(flex: 7, child: _buildItemsPanel()),
      ],
    );
  }

  /// Left-side content: header image slider, title, description,
  /// auction info rows, countdown and access button.
  Widget _buildDetailsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header Image & Title
        if (_currentAuction.imageUrl != null ||
            (_currentAuction.auctionImages != null &&
                _currentAuction.auctionImages!.isNotEmpty))
          AuctionImagesSliderWidget(
            images:
                _currentAuction.auctionImages != null &&
                    _currentAuction.auctionImages!.isNotEmpty
                ? _currentAuction.auctionImages!
                : [_currentAuction.imageUrl ?? ''],
            productID: _currentAuction.id ?? 0,
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentAuction.localizedTitle(context.locale.languageCode),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              gapH8,
              Text(
                _currentAuction.localizedDescription(
                  context.locale.languageCode,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              gapH16,

              // 2. Auction Info
              Text(
                AppStrings.auctionInformation.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              gapH8,
              _buildInfoRow(
                AppStrings.auctionNumber.tr(),
                _currentAuction.id.toString(),
              ),
              if (_currentAuction.liveStartDate != null) ...[
                _buildInfoRow(
                  'preAuctionStartsAt'.tr(),
                  _formatDate(_currentAuction.startDate),
                ),
                _buildInfoRow(
                  'liveStartsAt'.tr(),
                  _formatDate(_currentAuction.liveStartDate),
                ),
              ] else
                _buildInfoRow(
                  AppStrings.startsAt.tr(),
                  _formatDate(_currentAuction.startDate),
                ),
              if (_timeLeft > Duration.zero)
                Center(
                  child: Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(
                      '${_formatDuration(_timeLeft)} ${AppStrings.countdownStartsIn.tr()}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              gapH16,

              // 3. Access Button
              SizedBox(
                width: double.infinity,
                child: _isAccessLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildAccessButton(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Right-side content: search/filter toolbar + items grid or list.
  /// On tablets this is placed in a scrollable column; on phones it's
  /// rendered inline inside the single-column scroll view.
  Widget _buildItemsPanel() {
    // On tablets the items panel needs its own scroll; wrap with
    // SingleChildScrollView only when in tablet mode.
    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter row
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                ),
              ),
              gapW8,
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterProducts,
                  decoration: InputDecoration(
                    hintText: AppStrings.search.tr(),
                    suffixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              gapW8,
              // Grid Toggle
              Container(
                decoration: BoxDecoration(
                  color: _isGridView
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: _isGridView
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.grid_view,
                    color: _isGridView
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => _isGridView = true),
                ),
              ),
              gapW8,
              // List Toggle
              Container(
                decoration: BoxDecoration(
                  color: !_isGridView
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: !_isGridView
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.list,
                    color: !_isGridView
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => _isGridView = false),
                ),
              ),
            ],
          ),
          gapH16,

          // Section header
          Text(
            AppStrings.auctionItems.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          gapH8,

          // Items
          if (_filteredProducts.isNotEmpty && _isGridView)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // Use 3 columns on tablet, 2 on phone
                crossAxisCount: _isTablet ? 3 : 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];

                // Determine if this is the currently live item
                final bool isCurrentLiveItem =
                    _currentAuction.isPreAuction == false &&
                    _timeLeft == Duration.zero &&
                    _currentAuction.isExpired != true &&
                    _currentAuction.isCanceled != true &&
                    (product.id == _currentAuction.currentProductId ||
                        product.displayName == _currentAuction.currentProduct);

                return GestureDetector(
                  onTap: _canOpenItemBottomSheet
                      ? () => _showItemBottomSheet(
                          context,
                          product,
                          (_currentAuction.auctionProducts?.indexWhere(
                                    (p) => p.id == product.id,
                                  ) ??
                                  -1) +
                              1,
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrentLiveItem ? Colors.green.shade50 : null,
                      border: Border.all(
                        color: isCurrentLiveItem
                            ? Colors.green
                            : Colors.grey.shade200,
                        width: isCurrentLiveItem ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Product Image with bid-status overlay
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: Image.network(
                                  product.imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                ),
                              ),
                              // Bid status badge (top-right corner)
                              if (_buildBidStatusBadge(product.id) != null)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: _buildBidStatusBadge(product.id)!,
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppStrings.itemNumber.tr()}: ${(_currentAuction.auctionProducts?.indexWhere((p) => p.id == product.id) ?? -1) + 1}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              gapH4,
                              Text(
                                product.localizedName(
                                  context.locale.languageCode,
                                ),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              gapH4,
                              Row(
                                children: [
                                  Text(
                                    (_highestBids[product.id]?.bid ??
                                            product.minBidPrice)
                                        .toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  SvgPicture.asset(
                                    'assets/icons/RSA.svg',
                                    width: 14,
                                    height: 14,
                                    colorFilter: ColorFilter.mode(
                                      Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.color ??
                                          Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else if (_filteredProducts.isNotEmpty && !_isGridView)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredProducts.length,
              separatorBuilder: (context, index) => gapH8,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];

                // Determine if this is the currently live item
                final bool isCurrentLiveItem =
                    _currentAuction.isPreAuction == false &&
                    _timeLeft == Duration.zero &&
                    _currentAuction.isExpired != true &&
                    _currentAuction.isCanceled != true &&
                    (product.id == _currentAuction.currentProductId ||
                        product.displayName == _currentAuction.currentProduct);

                return GestureDetector(
                  onTap: _canOpenItemBottomSheet
                      ? () => _showItemBottomSheet(
                          context,
                          product,
                          (_currentAuction.auctionProducts?.indexWhere(
                                    (p) => p.id == product.id,
                                  ) ??
                                  -1) +
                              1,
                        )
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrentLiveItem ? Colors.green.shade50 : null,
                      border: Border.all(
                        color: isCurrentLiveItem
                            ? Colors.green
                            : Colors.grey.shade200,
                        width: isCurrentLiveItem ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl ?? '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                            ),
                          ),
                          gapW12,
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppStrings.itemNumber.tr()}: ${(_currentAuction.auctionProducts?.indexWhere((p) => p.id == product.id) ?? -1) + 1}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                gapH4,
                                Text(
                                  product.localizedName(
                                    context.locale.languageCode,
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Bid status badge
                                if (_buildBidStatusBadge(product.id) !=
                                    null) ...[
                                  gapH4,
                                  _buildBidStatusBadge(product.id)!,
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (_highestBids[product.id]?.bid ??
                                          product.minBidPrice)
                                      .toString(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                SvgPicture.asset(
                                  'assets/icons/RSA.svg',
                                  width: 16,
                                  height: 16,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.color ??
                                        Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  AppStrings.noResultsFound.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );

    // On tablets, wrap in a scrollable so the items panel can be scrolled
    // independently from the details panel.
    if (_isTablet) {
      return SingleChildScrollView(child: content);
    }
    return content;
  }
}
