import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathi/src/features/products/presentation/product_screen.dart';

import '../../features/products/domain/product_model.dart';
import '../constants/app_functions/app_functions.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings/app_strings.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final String? heroTag;

  const ProductCard({super.key, required this.product, this.heroTag});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    //if (widget.product.expiryDate != null) {
    //  final expiryDate = DateTime.parse(widget.product.expiryDate!);
    //  final now = DateTime.now();
    //  if (expiryDate.isAfter(now)) {
    //    setState(() {
    //      _remainingTime = expiryDate.difference(now);
    //    });
    //  } else {
    //    setState(() {
    //      _remainingTime = Duration.zero;
    //    });
    //  }
    //}
  }

  //String _formatDuration(Duration duration) {
  //  final hours = duration.inHours.toString().padLeft(2, '0');
  //  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  //  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  //  return '$hours:$minutes:$seconds';
  //}

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
            MaterialPageRoute(builder: (context) => ProductScreen()),
          );
        },
        onLongPress: () {
          AppFunctions.showImageDialog(
            context: context,
            imageUrl: widget.product.imageUrl ?? '',
            id: widget.product.id ?? 0,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Image Section with Heart Icon
            Expanded(
              flex: 5,
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
                        imageUrl: widget.product.imageUrl ?? '',
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
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              flex: 2,
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
                              builder: (context) => ProductScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Color(0xFF1B5E20)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          "${AppStrings.buyNow.tr()} :${widget.product.price ?? 0} ${AppStrings.currency.tr()}",
                          style: const TextStyle(
                            fontSize: 16,
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
