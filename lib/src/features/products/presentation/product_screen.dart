import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:turathy/src/features/notifications/presentation/notifications_screen.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/helper/analytics/analytics_service.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../cart/data/cart_repository.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../preorders/data/preorder_repository.dart';
import '../../preorders/presentation/preorder_screen.dart';
import '../domain/product_model.dart';

class ProductScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductScreen({super.key, required this.product});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _introController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  int _currentPage = 0;

  String get _languageCode => context.locale.languageCode;
  String get _productTitle => widget.product.localizedTitle(_languageCode);
  String get _productDescription =>
      widget.product.localizedDescription(_languageCode);

  List<String> get _images {
    // Use images list if available, otherwise use imageUrl
    List<String> rawImages = [];
    if (widget.product.images != null && widget.product.images!.isNotEmpty) {
      rawImages = widget.product.images!;
    } else if (widget.product.imageUrl != null &&
        widget.product.imageUrl!.isNotEmpty) {
      rawImages = [widget.product.imageUrl!];
    }

    // Add base URL prefix for relative paths (from uploads folder)
    return rawImages.map((url) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      // Prepend base URL for relative paths
      return '${EndPoints.baseUrl}$url';
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );
    _introController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.logScreenView(
        screenName: 'product_detail',
        screenClass: 'ProductScreen',
      );
      AnalyticsService.logProductViewed(
        productId: widget.product.id,
        category: widget.product.category,
        price: widget.product.price,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.productInfo.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.arrow_back_ios, color: Colors.black, size: 16),
              ],
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.black,
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _contentSlideAnimation,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 180),
                children: [
                  _buildImageCarousel(),
                  if (_images.length > 1) _buildThumbnailStrip(),
                  gapH16,
                  _buildHeaderSection(),
                  gapH24,
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _contentSlideAnimation,
                  child: _buildBottomBar(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _productTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          if (_productDescription.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _productDescription,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.65,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (_images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _images[index],
                  memCacheHeight: 800,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  progressIndicatorBuilder: (context, url, progress) => Center(
                    child: CircularProgressIndicator(value: progress.progress),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
            // Left Arrow
            if (_images.length > 1)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            // Right Arrow
            if (_images.length > 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage < _images.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            // Page Indicator
            if (_images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final isSelected = _currentPage == index;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 64,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: _images[index],
                  memCacheWidth: 200,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool isOwner = widget.product.userId == CachedVariables.userId;
    final bool isPreorder = widget.product.isPreorderContact;
    final bool isOutOfStock = !isPreorder && widget.product.stock <= 0;
    final bool isLowStock =
        !isPreorder && widget.product.stock > 0 && widget.product.stock <= 3;
    final Color stockColor = isOutOfStock
        ? const Color(0xFFC62828)
        : isLowStock
        ? const Color(0xFFEF6C00)
        : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: isOwner
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.yourProduct.tr(),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                _handlePrimaryAction();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfStock
                              ? Colors.grey.shade400
                              : const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          isPreorder
                              ? AppStrings.preorder.tr()
                              : isOutOfStock
                              ? AppStrings.outOfStock.tr()
                              : AppStrings.buyNow.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              gapW16,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isPreorder)
                    Text(
                      AppStrings.priceOnRequest.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.product.discountedPrice.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset('assets/icons/RSA.svg', height: 20),
                      ],
                    ),
                  if (!isPreorder && widget.product.hasDiscount)
                    Text(
                      '${widget.product.price?.toStringAsFixed(0) ?? '0'} ${AppStrings.currency.tr()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (!isPreorder && widget.product.hasDiscount)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      isPreorder
                          ? AppStrings.availableByPreorder.tr()
                          : isOutOfStock
                          ? AppStrings.outOfStock.tr()
                          : isLowStock
                          ? AppStrings.onlyLeft.tr()
                          : AppStrings.inStock.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrimaryAction() async {
    if (widget.product.isPreorderContact) {
      await _handlePreorder();
      return;
    }

    await _handleBuyNow();
  }

  Future<void> _handleBuyNow() async {
    final userId = CachedVariables.userId;

    if (userId == null) {
      _showSignInDialog();
      return;
    }

    try {
      await ref
          .read(cartRepositoryProvider)
          .addToCart(userId, widget.product.id);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handlePreorder() async {
    final userId = CachedVariables.userId;

    if (userId == null) {
      _showSignInDialog(isPreorder: true);
      return;
    }

    try {
      await ref.read(preorderRepositoryProvider).addItem(widget.product.id);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PreorderScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSignInDialog({bool isPreorder = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.signInRequired.tr(),
          textAlign: TextAlign.center,
        ),
        content: Text(
          isPreorder
              ? AppStrings.signInToPreorder.tr()
              : AppStrings.signInToAddToCart.tr(),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.signIn.tr()),
          ),
        ],
      ),
    );
  }

  //void _showBuyDialog() {
  //  showModalBottomSheet(
  //    context: context,
  //    isScrollControlled: true,
  //    backgroundColor: Colors.white,
  //    shape: const RoundedRectangleBorder(
  //      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //    ),
  //    builder: (context) => Padding(
  //      padding: EdgeInsets.only(
  //        bottom: MediaQuery.of(context).viewInsets.bottom,
  //      ),
  //      child: _BuyFormSheet(product: widget.product),
  //    ),
  //  );
  //}
}

class _BuyFormSheet extends ConsumerStatefulWidget {
  final ProductModel product;

  const _BuyFormSheet({required this.product});

  @override
  ConsumerState<_BuyFormSheet> createState() => _BuyFormSheetState();
}

class _BuyFormSheetState extends ConsumerState<_BuyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            gapH16,
            Text(
              AppStrings.shippingDetails.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            gapH24,
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.name.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? AppStrings.name.tr() : null,
            ),
            gapH16,
            TextFormField(
              controller: _mobileController,
              decoration: InputDecoration(
                labelText: AppStrings.mobileNumber.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty ?? true
                  ? AppStrings.mobileNumberRequired.tr()
                  : null,
            ),
            gapH16,
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: AppStrings.city.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? AppStrings.cityRequired.tr() : null,
            ),
            gapH16,
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: AppStrings.address.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              validator: (value) => value?.isEmpty ?? true
                  ? AppStrings.addressRequired.tr()
                  : null,
            ),
            gapH24,
            ElevatedButton(
              onPressed: _isLoading ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      AppStrings.submitOrder.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            gapH16,
          ],
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Call the order API when integrated
      // For now, show success message
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.orderPending.tr()),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
