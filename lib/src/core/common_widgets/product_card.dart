//import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/sign_in_screen.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';
import 'package:turathy/src/features/products/presentation/product_screen.dart';

import '../../features/products/domain/product_model.dart';
import '../constants/app_functions/app_functions.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final String? heroTag;

  const ProductCard({super.key, required this.product, this.heroTag});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductScreen(product: widget.product),
            ),
          );
        },
        onLongPress: () {
          AppFunctions.showImageDialog(
            context: context,
            imageUrl: _imageUrl,
            id: widget.product.id,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Image Section with Heart Icon
            Expanded(
              flex: 2,
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
                        width: double.infinity,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) => Center(
                              child: CircularProgressIndicator(
                                value: downloadProgress.progress,
                              ),
                            ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        ),
                      ),
                    ),
                  ),
                  // Heart Icon (Favorite)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: InkWell(
                      onTap: () {
                        final user = ref.read(authControllerProvider).value;
                        if (user == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInScreen(),
                            ),
                          );
                          return;
                        }
                        ref
                            .read(favoritesControllerProvider.notifier)
                            .toggleLikeProduct(widget.product);
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
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
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
                    // Description
                    Text(
                      widget.product.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    // Price and Time Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        //Text(
                        //  '${widget.product.minBidPrice ?? 0} ${AppStrings.currency.tr()}',
                        //  style: const TextStyle(
                        //    fontSize: 16,
                        //    fontWeight: FontWeight.bold,
                        //    color: Colors.black87,
                        //  ),
                        //),
                        // Remaining Time
                        //if (widget.product.expiryDate != null)
                        //  Text(
                        //    '${AppStrings.remainingTime.tr()}:${_formatDuration(_remainingTime)}',
                        //    style: const TextStyle(
                        //      fontSize: 12,
                        //      fontWeight: FontWeight.w600,
                        //      color: Color(0xFFD32F2F), // Red color
                        //    ),
                        //  ),
                      ],
                    ),
                    gapH4,
                    // Bid Now Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductScreen(product: widget.product),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Color(0xFF1B5E20)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        child: Text(
                          "${AppStrings.buyNow.tr()} :${widget.product.price ?? 0} ${AppStrings.currency.tr()}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
