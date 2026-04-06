/// {@category Presentation}
///
/// The primary landing page and discovery hub of the application.
/// 
/// [HomeScreen] serves as the central entry point, aggregating various content 
/// streams:
/// - **Interactive Search**: Managed by [SearchWidget].
/// - **Categorization**: Horizontal browsing via [CategoriesWidget].
/// - **Live Auctions**: High-urgency listings in [LiveAuctionsWidget].
/// - **Product Feed**: General marketplace listings in [ProductsListWidget].
/// 
/// The screen implements a deep-refresh pattern via [RefreshIndicator] that 
/// invalidates home-specific data providers simultaneously.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../auctions/data/auctions_repository.dart';
import '../../../products/data/products_repository.dart';
import '../../data/category_repository.dart';
import 'widgets/categories_widget/category_widget.dart';
import 'widgets/products_widget/live_auctions_widget.dart';
import 'widgets/products_widget/products_list_widget.dart';
import 'widgets/search_widget.dart';

// Note: OpenAuctionsWidget is currently excluded from the build tree due to 
// a parsing issue in the AuctionModel's JSON factory. 
// Ref: lib/src/features/home/presentation/home_screen/home_screen.dart:L5
// import 'package:turathy/src/features/home/presentation/home_screen/widgets/products_widget/open_auctions_widget.dart';

/// The root presentation layer for the Home tab.
class HomeScreen extends ConsumerWidget {
  /// Manages scroll offset for animations (e.g., shrinking headers).
  final ScrollController? scrollController;

  /// Creates a [HomeScreen] with an optional sync controller.
  const HomeScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sizes.p8),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              // Strategy: Batch invalidation of all home-screen data sources
              onRefresh: () async {
                ref.invalidate(homeLiveAuctionsProvider);
                ref.invalidate(openAuctionsProvider);
                ref.invalidate(productsListProvider);
                ref.invalidate(getAllCategoriesProvider);
                // Artificial delay to ensure UI smooths over the network ping
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    gapH12,
                    // ── Search & Filter Layer ─────────────────────────────────
                    const SearchWidget(),
                    gapH16,

                    // ── Taxonomy Layer ────────────────────────────────────────
                    const CategoriesWidget(),
                    gapH20,

                    // ── Urgency Layer (Live) ──────────────────────────────────
                    const LiveAuctionsWidget(),
                    gapH20,

                    // ── Activity Layer (Timed) ────────────────────────────────
                    // TODO: Restore OpenAuctionsWidget once AuctionModel parsing is fixed.
                    // const OpenAuctionsWidget(),
                    // gapH20,

                    // ── General Feed Layer ────────────────────────────────────
                    const ProductsListWidget(),
                    gapH20,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
