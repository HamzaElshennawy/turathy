import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/analytics/analytics_service.dart';
import 'package:turathy/src/core/common_widgets/auction_card.dart';
import 'package:turathy/src/core/common_widgets/shimmer_widget/shimmer_widget.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/home/presentation/home_screen/widgets/products_widget/auctions_filter_widget.dart';
import 'package:turathy/src/features/search/presentation/widgets/bottom_sheet_widget.dart';
import 'package:turathy/src/features/search/presentation/widgets/filter_widget/filter_widget.dart';

class AllAuctionsScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const AllAuctionsScreen({super.key, this.scrollController});

  @override
  ConsumerState<AllAuctionsScreen> createState() => _AllAuctionsScreenState();
}

class _AllAuctionsScreenState extends ConsumerState<AllAuctionsScreen> {
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'all_auctions_screen');
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = widget.scrollController?.offset ?? 0.0;
    final progress = (offset / 50).clamp(0.0, 1.0);
    if (_scrollProgress != progress) {
      setState(() {
        _scrollProgress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchBarHeight = 48 - (8 * _scrollProgress);
    final searchBarPadding = 16 - (8 * _scrollProgress);
    final filterButtonOpacity = (1.0 - _scrollProgress).clamp(0.0, 1.0);

    return Column(
      children: [
        // Search Bar and Filter Icon
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: searchBarPadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: searchBarHeight,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppStrings.search.tr(),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (filterButtonOpacity > 0) ...[
                gapW8,
                Opacity(
                  opacity: filterButtonOpacity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => BottomSheetWidget(
                            title: AppStrings.filters.tr(),
                            child: FilterWidget(
                              contentType: FilterContentType.auction,
                              onApply: () => ref.invalidate(filteredAuctionsProvider),
                              onClear: () => ref.invalidate(filteredAuctionsProvider),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Filter Tabs (only show when not scrolling much)
        if (_scrollProgress < 0.8)
          Opacity(
            opacity: (1.0 - (_scrollProgress / 0.8)).clamp(0.0, 1.0),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: AuctionsFilterWidget(),
            ),
          ),

        if (_scrollProgress < 0.8) gapH16,

        // Grid Content
        Expanded(
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final productsListValue = ref.watch(filteredAuctionsProvider);
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = (screenWidth / 350).floor().clamp(1, 3);

              return productsListValue.when(
                data: (data) {
                  if (data.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(filteredAuctionsProvider.future),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            controller: widget.scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: Center(
                                child: Text(AppStrings.noThingFound.tr()),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(filteredAuctionsProvider.future),
                    child: GridView.builder(
                      controller: widget.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: data.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: .76,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final product = data[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: AuctionCard(
                            auction: product,
                            heroTag: 'all_auctions_${product.id}_$index',
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => GridView.builder(
                  controller: widget.scrollController,
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: 4,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: .7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) =>
                      const ShimmerWidget(width: 400, height: 0),
                ),
                error: (error, stackTrace) => RefreshIndicator(
                  onRefresh: () => ref.refresh(filteredAuctionsProvider.future),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: widget.scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: Center(child: Text('Error: $error')),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


