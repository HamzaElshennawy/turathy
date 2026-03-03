import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_item_details_widget.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/live_auction_screen.dart';
import 'package:turathy/src/features/notifications/presentation/notifications_screen.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../authintication/presentation/sign_in_screen.dart';
import '../../domain/auction_model.dart';
import '../../domain/auction_access_model.dart';
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
  StreamSubscription? _bidSubscription;
  StreamSubscription? _auctionStartedSubscription;
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
    final isAdmin = _currentAuction.userId == CachedVariables.userId;
    if (isAdmin) {
      setState(() {
        _accessStatus = 'GRANTED';
        _isAccessLoading = false;
      });
      return;
    }

    if (CachedVariables.userId == null) {
      setState(() {
        _accessStatus = 'REQUIRED';
        _isAccessLoading = false;
      });
      return;
    }

    try {
      final repository = ref.read(productsRepositoryProvider);
      final response = await repository.checkUserAccess(
        CachedVariables.userId ?? 0,
        _currentAuction.id ?? 0,
      );

      setState(() {
        _accessStatus = response.status.toUpperCase();
        _isAccessLoading = false;
      });
    } catch (e) {
      debugPrint("Error checking auction access: $e");
      setState(() {
        _accessStatus = 'ERROR';
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
    try {
      final repository = ref.read(productsRepositoryProvider);
      final response = await repository.requestAccess(
        RequestAuctionAccessDto(
          userId: CachedVariables.userId ?? 0,
          auctionId: _currentAuction.id ?? 0,
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
      setState(() {
        _accessStatus = 'ERROR';
      });
    } finally {
      setState(() {
        _isAccessLoading = false;
      });
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
    _timer?.cancel();
    _searchController.dispose();
    _bidSubscription?.cancel();
    _auctionStartedSubscription?.cancel();
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
          return product.product?.toLowerCase().contains(searchQuery) ?? false;
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
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat(
      'd MMMM, h a',
    ).format(date); // Example: 14 December, 10 AM
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
            p.product == _currentAuction.currentProduct ||
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
        isHighestInactive = true;
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
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showItemBottomSheet(
    BuildContext context,
    AuctionProducts product,
    int itemIndex,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (sheetContext, ref, child) {
            // Watch for real-time bid updates so the entire sheet rebuilds
            // ignore: unused_local_variable
            final lastBid = ref.watch(currentBidStateProvider);

            // Merge real-time bids into a combined list for this product
            final initialBids =
                product.bids ?? _currentAuction.auctionBids ?? [];

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppStrings.itemNumber.tr()}: ${itemIndex}',
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
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuctionItemDetailsWidget(
                                auction: _currentAuction,
                                activeProduct: product,
                                isAuctionEnded: false,
                              ),
                              // Real-time bid history for this product
                              gapH16,
                              AuctionBidsHistoryWidget(
                                initialBids: initialBids,
                                productId: product.id,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Only show max bid controls if pre-auction has started
                      if (_hasPreAuctionStarted) ...[
                        gapH16,
                        AuctionBiddingControlsWidget(
                          auction: _currentAuction,
                          selectedProduct: product,
                          showOnlyMaxBid: true,
                          onPlaceBid: (qty, price, productId) {
                            if (productId != null) {
                              final socketActions = ref.read(
                                socketActionsProvider,
                              );
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
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                      100,
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
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
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
                                              AppStrings.bidPlacedSuccessfully
                                                  .tr(),
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
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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
                new MaterialPageRoute(
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
          child: SingleChildScrollView(
            // physics: const AlwaysScrollableScrollPhysics() is needed for RefreshIndicator
            // to work even if the content doesn't overflow the screen.
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
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
                        _currentAuction.title ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      gapH8,
                      Text(
                        _currentAuction.description ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      gapH16,

                      // 2. Auction Info
                      Text(
                        AppStrings.auctionInformation
                            .tr(), // AppStrings.auctionInformation.tr()
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                      //_buildInfoRow(
                      //  AppStrings.endsAt.tr(),
                      //  _formatDate(_currentAuction.expiryDate),
                      //),
                      //gapH8,
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

                      // 3. Bid Now Button
                      SizedBox(
                        width: double.infinity,
                        child: _isAccessLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildAccessButton(context),
                      ),
                      gapH16,

                      // 4. Search & Filter
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
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),

                          gapW8,
                          // Grid Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: _isGridView
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1)
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
                              onPressed: () {
                                setState(() {
                                  _isGridView = true;
                                });
                              },
                            ),
                          ),
                          gapW8,
                          // List Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: !_isGridView
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1)
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
                              onPressed: () {
                                setState(() {
                                  _isGridView = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      gapH16,

                      // 5. Auction Items
                      Text(
                        AppStrings.auctionItems.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      gapH8,
                      if (_filteredProducts.isNotEmpty && _isGridView)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75, // Adjust as needed
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
                                (product.id ==
                                        _currentAuction.currentProductId ||
                                    product.product ==
                                        _currentAuction.currentProduct);

                            return GestureDetector(
                              onTap: _canOpenItemBottomSheet
                                  ? () => _showItemBottomSheet(
                                      context,
                                      product,
                                      (_currentAuction.auctionProducts
                                                  ?.indexWhere(
                                                    (p) => p.id == product.id,
                                                  ) ??
                                              -1) +
                                          1,
                                    )
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCurrentLiveItem
                                      ? Colors.green.shade50
                                      : null,
                                  border: Border.all(
                                    color: isCurrentLiveItem
                                        ? Colors.green
                                        : Colors.grey.shade200,
                                    width: isCurrentLiveItem ? 2.0 : 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Product Image with bid-status overlay
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(8),
                                                ),
                                            child: Image.network(
                                              product.imageUrl ?? '',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          // Bid status badge (top-right corner)
                                          if (_buildBidStatusBadge(
                                                product.id,
                                              ) !=
                                              null)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: _buildBidStatusBadge(
                                                product.id,
                                              )!,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${AppStrings.itemNumber.tr()}: ${(_currentAuction.auctionProducts?.indexWhere((p) => p.id == product.id) ?? -1) + 1}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          gapH4,
                                          Text(
                                            product.product ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
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
                                                (_highestBids[product.id]
                                                            ?.bid ??
                                                        product.minBidPrice)
                                                    .toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              SvgPicture.asset(
                                                'assets/icons/RSA.svg',
                                                width: 14,
                                                height: 14,
                                                colorFilter: ColorFilter.mode(
                                                  Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.color ??
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
                                (product.id ==
                                        _currentAuction.currentProductId ||
                                    product.product ==
                                        _currentAuction.currentProduct);

                            return GestureDetector(
                              onTap: _canOpenItemBottomSheet
                                  ? () => _showItemBottomSheet(
                                      context,
                                      product,
                                      (_currentAuction.auctionProducts
                                                  ?.indexWhere(
                                                    (p) => p.id == product.id,
                                                  ) ??
                                              -1) +
                                          1,
                                    )
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCurrentLiveItem
                                      ? Colors.green.shade50
                                      : null,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Product Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          product.imageUrl ?? '',
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${AppStrings.itemNumber.tr()}: ${(_currentAuction.auctionProducts?.indexWhere((p) => p.id == product.id) ?? -1) + 1}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                            gapH4,
                                            Text(
                                              product.product ?? '',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            // Bid status badge
                                            if (_buildBidStatusBadge(
                                                  product.id,
                                                ) !=
                                                null) ...[
                                              gapH4,
                                              _buildBidStatusBadge(product.id)!,
                                            ],
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              (_highestBids[product.id]?.bid ??
                                                      product.minBidPrice)
                                                  .toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(width: 4),
                                            SvgPicture.asset(
                                              'assets/icons/RSA.svg',
                                              width: 16,
                                              height: 16,
                                              colorFilter: ColorFilter.mode(
                                                Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.color ??
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
