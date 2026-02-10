import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart'
    as auctions_repo;
import 'package:turathy/src/features/home/data/category_repository.dart';
import 'package:turathy/src/features/products/data/products_repository.dart'
    as products_repo;

class CreateItemScreen extends ConsumerStatefulWidget {
  const CreateItemScreen({super.key});

  @override
  ConsumerState<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends ConsumerState<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isAuction = false;
  bool _isLoading = false;

  // Common Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  // Product-specific Controllers
  final _brandController = TextEditingController();
  final _materialController = TextEditingController();
  final _conditionController = TextEditingController();
  final _ageController = TextEditingController();

  // Auction-specific Controllers
  final _actualPriceController = TextEditingController();
  final _minBidPriceController = TextEditingController();
  final _bidPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _originController = TextEditingController();
  final _usageController = TextEditingController();

  // Auction-specific State
  DateTime? _expiryDate;
  DateTime? _startDate;
  String _auctionType = 'Live'; // Live or Open

  // Common State
  int? _selectedCategoryId;
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _materialController.dispose();
    _conditionController.dispose();
    _ageController.dispose();
    _actualPriceController.dispose();
    _minBidPriceController.dispose();
    _bidPriceController.dispose();
    _quantityController.dispose();
    _originController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final now = DateTime.now();
    final picked = await showDateTimePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  Future<DateTime?> showDateTimePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null) return null;

    if (!mounted) return date;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return date;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseSelectAtLeastOneImage.tr())),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.pleaseSelectCategory.tr())),
      );
      return;
    }

    if (_isAuction && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.expiryDate.tr()} ${AppStrings.required_.tr()}',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isAuction) {
        final auctionData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'actualPrice': int.tryParse(_actualPriceController.text) ?? 0,
          'minBidPrice': int.tryParse(_minBidPriceController.text) ?? 0,
          'bidPrice': int.tryParse(_bidPriceController.text) ?? 0,
          'quantity': int.tryParse(_quantityController.text) ?? 1,
          'expiryDate': _expiryDate!.toIso8601String(),
          'category_id': _selectedCategoryId,
          'user_id': CachedVariables.userId,
          'type': _auctionType,
          if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
          if (_materialController.text.isNotEmpty)
            'material': _materialController.text,
          if (_ageController.text.isNotEmpty)
            'approximateAge': _ageController.text,
          if (_conditionController.text.isNotEmpty)
            'condition': _conditionController.text,
          if (_originController.text.isNotEmpty)
            'origin': _originController.text,
          if (_usageController.text.isNotEmpty) 'usage': _usageController.text,
        };

        await ref
            .read(auctions_repo.productsRepositoryProvider)
            .addAuction(auctionData, _selectedImages);
      } else {
        final productData = {
          'title': _titleController.text,
          'name': _titleController.text,
          'description': _descriptionController.text,
          'price': _priceController.text,
          'category_id': _selectedCategoryId,
          'user_id': CachedVariables.userId,
          'brand': _brandController.text,
          'material': _materialController.text,
          'condition': _conditionController.text,
          'approximateAge': _ageController.text,
          'stock': 1,
        };

        await ref
            .read(products_repo.productsRepositoryProvider)
            .addProduct(productData, _selectedImages);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.itemCreatedSuccessfully.tr())),
        );
        Navigator.pop(context);
        ref.invalidate(products_repo.myProductsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(getAllCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAuction
              ? AppStrings.createAuction.tr()
              : AppStrings.createProduct.tr(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle Switch
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(AppStrings.product.tr()),
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(AppStrings.auction.tr()),
                    icon: const Icon(Icons.gavel_outlined),
                  ),
                ],
                selected: {_isAuction},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isAuction = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF2D4739);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return Colors.black;
                  }),
                ),
              ),
              gapH24,

              // Images Section
              Text(
                '${AppStrings.images.tr()} (${_selectedImages.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              gapH8,
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  separatorBuilder: (context, index) => gapW8,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    final image = _selectedImages[index - 1];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(image.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index - 1),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              gapH24,

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppStrings.title.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? AppStrings.required_.tr() : null,
              ),
              gapH16,

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppStrings.description.tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty == true ? AppStrings.required_.tr() : null,
              ),
              gapH16,

              // Category Dropdown
              categoriesAsync.when(
                data: (categories) {
                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: AppStrings.category.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat.id,
                        child: Text(cat.name ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                    validator: (val) =>
                        val == null ? AppStrings.required_.tr() : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Text('${AppStrings.errorLoadingCategories.tr()}: $e'),
              ),
              gapH16,

              // ============ AUCTION-SPECIFIC FIELDS ============
              if (_isAuction) ...[
                // Auction Type Selector
                DropdownButtonFormField<String>(
                  value: _auctionType,
                  decoration: InputDecoration(
                    labelText: AppStrings.auctionTypeLabel.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: ['Live', 'Open']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _auctionType = val ?? 'Live';
                    });
                  },
                ),
                gapH16,

                // Actual Price (حد السوم)
                TextFormField(
                  controller: _actualPriceController,
                  decoration: InputDecoration(
                    labelText: AppStrings.actualPrice.tr(),
                    border: const OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty == true ? AppStrings.required_.tr() : null,
                ),
                gapH16,

                // Min Bid Price (فتح الباب)
                TextFormField(
                  controller: _minBidPriceController,
                  decoration: InputDecoration(
                    labelText: AppStrings.minBidPriceLabel.tr(),
                    border: const OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty == true ? AppStrings.required_.tr() : null,
                ),
                gapH16,

                // Bid Increment (فرق السوم)
                TextFormField(
                  controller: _bidPriceController,
                  decoration: InputDecoration(
                    labelText: AppStrings.bidIncrement.tr(),
                    border: const OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty == true ? AppStrings.required_.tr() : null,
                ),
                gapH16,

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: AppStrings.auctionQuantity.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty == true ? AppStrings.required_.tr() : null,
                ),
                gapH16,

                // Expiry Date (Required)
                InkWell(
                  onTap: () => _pickDate(isExpiry: true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppStrings.expiryDate.tr(),
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _expiryDate != null
                          ? _formatDate(_expiryDate!)
                          : AppStrings.selectDate.tr(),
                      style: TextStyle(
                        color: _expiryDate != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                gapH16,

                // Start Date (Optional)
                InkWell(
                  onTap: () => _pickDate(isExpiry: false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppStrings.startDate.tr(),
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _startDate != null
                          ? _formatDate(_startDate!)
                          : AppStrings.selectDate.tr(),
                      style: TextStyle(
                        color: _startDate != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                gapH16,

                // Material (Optional - shared with products)
                TextFormField(
                  controller: _materialController,
                  decoration: InputDecoration(
                    labelText: AppStrings.materialOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH16,

                // Approximate Age (Optional)
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: AppStrings.approximateAgeOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH16,

                // Condition (Optional)
                TextFormField(
                  controller: _conditionController,
                  decoration: InputDecoration(
                    labelText: AppStrings.conditionOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH16,

                // Origin (Optional)
                TextFormField(
                  controller: _originController,
                  decoration: InputDecoration(
                    labelText: AppStrings.originOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH16,

                // Usage (Optional)
                TextFormField(
                  controller: _usageController,
                  decoration: InputDecoration(
                    labelText: AppStrings.usageOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH24,
              ],

              // ============ PRODUCT-SPECIFIC FIELDS ============
              if (!_isAuction) ...[
                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: AppStrings.price.tr(),
                    border: const OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty == true ? AppStrings.required_.tr() : null,
                ),
                gapH16,

                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    labelText: AppStrings.brandOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH16,
                TextFormField(
                  controller: _materialController,
                  decoration: InputDecoration(
                    labelText: AppStrings.materialOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH16,
                TextFormField(
                  controller: _conditionController,
                  decoration: InputDecoration(
                    labelText: AppStrings.conditionOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH16,
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: AppStrings.approximateAgeOptional.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                gapH24,
              ],

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D4739),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isAuction
                            ? AppStrings.createAuction.tr()
                            : AppStrings.createProduct.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
