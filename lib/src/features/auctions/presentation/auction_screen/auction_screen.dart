import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/live_auction_screen.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../authintication/presentation/sign_in_screen.dart';
import '../../domain/auction_model.dart';
import 'widgets/auction_images_slider_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.auction.auctionProducts ?? [];
    _calculateTimeLeft();
    _startTimer();
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

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Image & Title
              if (widget.auction.imageUrl != null ||
                  (widget.auction.auctionImages != null &&
                      widget.auction.auctionImages!.isNotEmpty))
                AuctionImagesSliderWidget(
                  images:
                      widget.auction.auctionImages != null &&
                          widget.auction.auctionImages!.isNotEmpty
                      ? widget.auction.auctionImages!
                      : [widget.auction.imageUrl ?? ''],
                  productID: widget.auction.id ?? 0,
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.auction.title ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    gapH8,
                    Text(
                      widget.auction.description ?? '',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    gapH16,

                    // 2. Auction Info
                    Text(
                      AppStrings.auctionInformation
                          .tr(), // AppStrings.auctionInformation.tr()
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    gapH8,
                    _buildInfoRow(
                      AppStrings.auctionNumber.tr(),
                      widget.auction.id.toString(),
                    ),
                    _buildInfoRow(
                      AppStrings.startsAt.tr(),
                      _formatDate(widget.auction.startDate),
                    ),
                    _buildInfoRow(
                      AppStrings.endsAt.tr(),
                      _formatDate(widget.auction.expiryDate),
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
                      child: OutlinedButton(
                        onPressed: _timeLeft > Duration.zero
                            ? null
                            : () {
                                if (CachedVariables.userId == null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SignInScreen(),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LiveAuctionScreen(
                                      auctionId: widget.auction.id ?? 0,
                                      isAdmin:
                                          widget.auction.userId ==
                                          CachedVariables.userId,
                                    ),
                                  ),
                                );
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: _timeLeft > Duration.zero
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: _timeLeft > Duration.zero
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                        ),
                        child: Text(
                          _timeLeft > Duration.zero
                              ? AppStrings.upcoming
                                    .tr() // "Upcoming"
                              : AppStrings.joinNow.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ), // "Bid Now"
                      ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                                    childAspectRatio: 0.75, // Adjust as needed
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return Container(
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
                                                    Icons.image_not_supported,
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
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            gapH4,
                                            Text(
                                              '${product.minBidPrice}\$',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                                return Container(
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                                overflow: TextOverflow.ellipsis,
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
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                      ],
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
    );
  }
}
