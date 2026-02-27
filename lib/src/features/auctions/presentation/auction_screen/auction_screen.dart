import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_item_details_widget.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/live_auction_screen.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../authintication/presentation/sign_in_screen.dart';
import '../../domain/auction_model.dart';
import '../../domain/auction_access_model.dart';
import '../../data/auctions_repository.dart';
import 'widgets/auction_images_slider_widget.dart';
import 'package:turathy/src/core/helper/socket/socket_providers.dart';

class AuctionScreen extends ConsumerStatefulWidget {
  final AuctionModel auction;

  const AuctionScreen(this.auction, {super.key});

  @override
  ConsumerState<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends ConsumerState<AuctionScreen> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isGridView = false; // State for toggling view
  List<AuctionProducts> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  String? _accessStatus;
  bool _isAccessLoading = true;
  bool _isLoadingDetails = false;
  late AuctionModel _currentAuction;

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
          _filteredProducts = _currentAuction.auctionProducts ?? [];
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
        _filteredProducts = widget.auction.auctionProducts ?? [];
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.auction.auctionProducts ?? [];
      } else {
        _filteredProducts =
            widget.auction.auctionProducts
                ?.where(
                  (product) =>
                      product.product?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false,
                )
                .toList() ??
            [];
      }
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

  Widget _buildInfoRow(String label, String value) {
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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

    VoidCallback? onPressed;
    String buttonText = '';
    Color? buttonColor;
    bool isPreAuction = _currentAuction.isPreAuction;

    if (isOwner || isGranted) {
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

  void _showItemBottomSheet(BuildContext context, AuctionProducts product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                        '${AppStrings.itemNumber.tr()}: ${product.id}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
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
                        ],
                      ),
                    ),
                  ),
                  // Only show max bid controls if pre-auction has started
                  if (_hasPreAuctionStarted) ...[
                    gapH16,
                    Consumer(
                      builder: (context, ref, child) {
                        final socketActions = ref.read(socketActionsProvider);
                        return AuctionBiddingControlsWidget(
                          auction: _currentAuction,
                          selectedProduct: product,
                          showOnlyMaxBid: true,
                          onPlaceBid: (qty, price, productId) {
                            if (productId != null) {
                              socketActions.placeBid(
                                _currentAuction.id ?? 0,
                                CachedVariables.userId ?? 0,
                                price.toDouble(),
                                productId,
                              );
                              final overlay = Overlay.of(context);
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
                        );
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
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {},
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
                      _buildInfoRow(
                        AppStrings.endsAt.tr(),
                        _formatDate(_currentAuction.expiryDate),
                      ),
                      gapH8,
                      if (_timeLeft > Duration.zero)
                        Center(
                          child: Text(
                            '${AppStrings.countdownStartsIn.tr()} ${_formatDuration(_timeLeft)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                              onPressed: () {},
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
                      if (_filteredProducts.isNotEmpty)
                        _isGridView
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredProducts.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio:
                                          0.75, // Adjust as needed
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return GestureDetector(
                                    onTap: _canOpenItemBottomSheet
                                        ? () => _showItemBottomSheet(
                                            context,
                                            product,
                                          )
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Product Image
                                          Expanded(
                                            child: ClipRRect(
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
                                                        Icons
                                                            .image_not_supported,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${AppStrings.itemNumber.tr()}: ${product.id}',
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                gapH4,
                                                Text(
                                                  '${product.minBidPrice}\$',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
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
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredProducts.length,
                                separatorBuilder: (context, index) => gapH8,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return GestureDetector(
                                    onTap: _canOpenItemBottomSheet
                                        ? () => _showItemBottomSheet(
                                            context,
                                            product,
                                          )
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade200,
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                product.imageUrl ?? '',
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      width: 80,
                                                      height: 80,
                                                      color: Colors.grey[200],
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported,
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
                                                    '${AppStrings.itemNumber.tr()}: ${product.id}',
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
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                '${product.minBidPrice}\$',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
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
