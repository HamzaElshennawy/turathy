import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/authintication/presentation/auth_controller.dart';
import 'package:turathy/src/features/authintication/presentation/sign_in_screen.dart';
import 'package:turathy/src/features/favorites/presentation/controllers/favorites_provider.dart';
import 'package:turathy/src/features/products/presentation/product_screen.dart';

import '../../features/products/domain/product_model.dart';
import '../constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';

class HorizontalProductCard extends ConsumerWidget {
  final ProductModel product;

  const HorizontalProductCard({super.key, required this.product});

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
    final favoritesState = ref.watch(favoritesControllerProvider);
    final isLiked = favoritesState.maybeWhen(
      data: (state) => state.likedProductIds.contains(product.id),
      orElse: () => false,
    );

    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 140, // Fixed height for horizontal card
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
              builder: (context) => ProductScreen(product: product),
            ),
          );
        },
        child: Row(
          children: [
            // Image Section
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
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 50),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left:
                        8, // Changed from right to left for horizontal card logic if needed, but sticking to top-left of image
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
                            .toggleLikeProduct(product);
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
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                    ),
                    Row(
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
                        // ElevatedButton(
                        //   onPressed: () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) =>
                        //             ProductScreen(product: product),
                        //       ),
                        //     );
                        //   },
                        //   style: ElevatedButton.styleFrom(
                        //     foregroundColor: const Color(0xFF1B5E20),
                        //     backgroundColor: Colors.white,
                        //     side: const BorderSide(color: Color(0xFF1B5E20)),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(18),
                        //     ),
                        //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        //      minimumSize: const Size(0, 32),
                        //      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        //   ),
                        //   child: Text(
                        //     AppStrings.details.tr(),
                        //     style: const TextStyle(fontSize: 12),
                        //   ),
                        // ),
                      ],
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
