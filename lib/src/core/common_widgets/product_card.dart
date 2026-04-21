/// {@category Components}
///
/// A primary list-item component representing a [ProductModel].
/// 
/// This widget is designed for fixed-price item displays in galleries or search results.
/// Key features include:
/// - **Asset Handling**: Smart image resolution logic covering remote, relative, and list-based paths.
/// - **Visual Polish**: High-quality [Hero] animations and shadow-based elevation.
/// - **Quick Actions**: Integrated "Buy Now" CTA with price display and "Favorite" toggling.
/// - **Interactive Previews**: Long-press support for fullscreen image inspection.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/sign_in_screen.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';
import 'package:turathy/src/features/products/presentation/product_details_wrapper.dart';

import '../../features/products/domain/product_model.dart';
import '../constants/app_functions/app_functions.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings/app_strings.dart';

/// A sleek, consumer-aware card for displaying fixed-price product summaries.
class ProductCard extends ConsumerStatefulWidget {
  /// The product entity containing title, price, and media metadata.
  final ProductModel product;

  /// Optional identifier for [Hero] transition animations.
  /// Defaults to [product.id] if not specified.
  final String? heroTag;

  /// Creates a [ProductCard] for the given [product].
  const ProductCard({super.key, required this.product, this.heroTag});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  @override
  void initState() {
    super.initState();
  }

  /// Calculates the absolute URL for the product's primary image.
  /// 
  /// Logic heuristic:
  /// 1. Check `product.images` list; take the first entry if available.
  /// 2. If empty, fallback to the single `product.imageUrl` field.
  /// 3. If the resulting path is relative, prepend [EndPoints.baseUrl].
  /// 4. Return an empty string if no valid path exists.
  String get _imageUrl {
    String? url;
    if (widget.product.images != null && widget.product.images!.isNotEmpty) {
      url = widget.product.images!.first;
    } else if (widget.product.imageUrl != null &&
        widget.product.imageUrl!.isNotEmpty) {
      url = widget.product.imageUrl!;
    }

    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${EndPoints.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    // Sync with the global reactive favorites state
    final favoritesState = ref.watch(favoritesControllerProvider);
    final isLiked = favoritesState.maybeWhen(
      data: (state) => state.likedProductIds.contains(widget.product.id),
      orElse: () => false,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
        onTap: () => _navigateToDetails(),
        onLongPress: () {
          // Visual-first feature: Inspect the product image in a fullscreen dialog
          AppFunctions.showImageDialog(
            context: context,
            imageUrl: _imageUrl,
            id: widget.product.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero Media Layer ────────────────────────────────────────────
            Expanded(
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Hero(
                    tag: widget.heroTag ?? widget.product.id,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _imageUrl,
                        memCacheHeight: 400,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder: (context, url, progress) => Center(
                          child: CircularProgressIndicator(value: progress.progress),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        ),
                      ),
                    ),
                  ),
                  // Floating Interaction: Wishlist/Like
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildHeartIcon(isLiked),
                  ),
                  if (widget.product.hasDiscount &&
                      !widget.product.isPreorderContact)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildDiscountBadge(),
                    ),
                ],
              ),
            ),

            // ── Information & Purchase Layer ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.product.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  gapH4,
                  Text(
                    widget.product.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                  ),
                  gapH8,
                  _buildStockChip(),
                  gapH16,
                  // Buy Now Button with integrated price display
                  _buildBuyNowButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Internal: Builds the favoriting toggle with authentication guard.
  Widget _buildHeartIcon(bool isLiked) {
    return InkWell(
      onTap: () {
        final user = ref.read(authControllerProvider).value;
        if (user == null) {
          // Ensure valid session before allowing wishlist mutations
          Navigator.push(context, MaterialPageRoute(builder: (_) => SignInScreen()));
          return;
        }
        ref.read(favoritesControllerProvider.notifier).toggleLikeProduct(widget.product);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  /// Internal: Builds the primary call-to-action with localized price labels.
  Widget _buildBuyNowButton() {
    final priceText = widget.product.discountedPrice.toStringAsFixed(0);
    final originalPrice = widget.product.price ?? 0;
    final isPreorder = widget.product.isPreorderContact;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _navigateToDetails(),
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF1B5E20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPreorder
                  ? AppStrings.preorder.tr()
                  : "${AppStrings.buyNow.tr()} :$priceText ${AppStrings.currency.tr()}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (isPreorder)
              Text(
                AppStrings.priceOnRequest.tr(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              )
            else if (widget.product.hasDiscount)
              Text(
                "${originalPrice.toStringAsFixed(0)} ${AppStrings.currency.tr()}",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppStrings.discountPercentOff.tr(
          args: [widget.product.discount.toStringAsFixed(0)],
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStockChip() {
    if (widget.product.isPreorderContact) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            AppStrings.availableByPreorder.tr(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1565C0),
            ),
          ),
        ),
      );
    }

    final bool isLowStock = widget.product.stock > 0 && widget.product.stock <= 3;
    final bool isOutOfStock = widget.product.stock <= 0;
    final Color backgroundColor = isOutOfStock
        ? const Color(0xFFFFEBEE)
        : isLowStock
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9);
    final Color foregroundColor = isOutOfStock
        ? const Color(0xFFC62828)
        : isLowStock
            ? const Color(0xFFEF6C00)
            : const Color(0xFF2E7D32);
    final String text = isOutOfStock
        ? AppStrings.outOfStock.tr()
        : isLowStock
            ? AppStrings.onlyLeft.tr(args: [widget.product.stock.toString()])
            : AppStrings.inStock.tr();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }

  /// Internal: Routes the user to the full product details view.
  void _navigateToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsWrapper(productId: widget.product.id),
      ),
    );
  }
}

