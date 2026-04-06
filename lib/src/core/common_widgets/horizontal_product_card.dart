/// {@category Components}
///
/// A compact, horizontal-orientation card for displaying [ProductModel] summaries.
/// 
/// Ideal for dense lists or related-item carousels where vertical height is limited.
/// This component provides:
/// - **Horizontal Layout**: Side-by-side arrangement of product media and text.
/// - **Integrated Price UI**: Highlights the fixed price with localized currency units.
/// - **Reactive Wishlist**: Real-time heart toggle with underlying favorite state sync.
/// - **Smart Media Resolution**: Handles complex image path lookups from lists or single URLs.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/sign_in_screen.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';
import 'package:turathy/src/features/products/presentation/product_screen.dart';

import '../../features/products/domain/product_model.dart';
import '../constants/app_strings/app_strings.dart';

/// A landscape-oriented preview card for fixed-price product entities.
class HorizontalProductCard extends ConsumerWidget {
  /// The product entity to be visualized.
  final ProductModel product;

  /// Creates a [HorizontalProductCard] for the given [product].
  const HorizontalProductCard({super.key, required this.product});

  /// Computes the absolute URL for the product's primary visual asset.
  /// 
  /// prioritizes:
  /// 1. `product.images[0]`
  /// 2. `product.imageUrl`
  /// 3. Prefixes relative paths with [EndPoints.baseUrl].
  String get _imageUrl {
    String? url;
    if (product.images != null && product.images!.isNotEmpty) {
      url = product.images!.first;
    } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      url = product.imageUrl!;
    }

    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${EndPoints.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync with the global wishlist/favorites state
    final favoritesState = ref.watch(favoritesControllerProvider);
    final isLiked = favoritesState.maybeWhen(
      data: (state) => state.likedProductIds.contains(product.id),
      orElse: () => false,
    );

    return Container(
      height: 140, // Standardized height for horizontal item cards
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetails(context),
        child: Row(
          children: [
            // ── Primary Media Layer ─────────────────────────────────────────
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: _imageUrl,
                      memCacheHeight: 400,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 50),
                      ),
                    ),
                  ),
                  // Top-Left Floating Action: Favorite
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildHeartIcon(context, ref, isLiked),
                  ),
                ],
              ),
            ),
            
            // ── Information & Metadata Layer ────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTextContent(),
                    _buildPriceLayer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Internal: Builds the favoriting toggle with session guard.
  Widget _buildHeartIcon(BuildContext context, WidgetRef ref, bool isLiked) {
    return InkWell(
      onTap: () {
        final user = ref.read(authControllerProvider).value;
        if (user == null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen()));
          return;
        }
        ref.read(favoritesControllerProvider.notifier).toggleLikeProduct(product);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  /// Internal: Renders title and description with overflow management.
  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.description ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.3,
          ),
        ),
      ],
    );
  }

  /// Internal: Renders the price value with localized currency units.
  Widget _buildPriceLayer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${product.price ?? 0} ${AppStrings.currency.tr()}",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  /// Internal: Routes the context to the full [ProductScreen] details.
  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
    );
  }
}

