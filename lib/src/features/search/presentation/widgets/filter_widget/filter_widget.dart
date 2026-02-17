import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../auctions/data/auctions_repository.dart';
import '../filter_chip_widget.dart';
import 'filter_widget_controller.dart';

class FilterWidget extends ConsumerWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedConditionIndex = ref
        .watch(filterWidgetControllerProvider.notifier)
        .selectedConditionIndex;
    final selectedAgeIndex = ref
        .watch(filterWidgetControllerProvider.notifier)
        .selectedAgeIndex;
    final selectedCategoryIndex = ref
        .watch(filterWidgetControllerProvider.notifier)
        .selectedCategoryIndex;
    final minPrice = ref.watch(filterWidgetControllerProvider).minPrice;
    final maxPrice = ref.watch(filterWidgetControllerProvider).maxPrice;
    final isAllOffersSelected = ref
        .watch(filterWidgetControllerProvider)
        .isAllOffersSelected;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.offers.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    gapH8,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChipWidget(
                          text: AppStrings.allOffers.tr(),
                          isSelected: isAllOffersSelected,
                          onTap: () {
                            ref
                                .read(filterWidgetControllerProvider.notifier)
                                .selectAllOffers();
                          },
                        ),
                      ],
                    ),
                    gapH16,
                    // Price Range
                    // Using controllers to manage text field state
                    _PriceRangeWidget(minPrice: minPrice, maxPrice: maxPrice),
                    gapH16,
                    _displayFilters(
                      AppStrings.condition.tr(),
                      ref
                          .read(filterWidgetControllerProvider.notifier)
                          .conditions,
                      [selectedConditionIndex],
                      context,
                      (index) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .selectCondition(index);
                      },
                    ),
                    gapH16,
                    _displayFilters(
                      AppStrings.age.tr(),
                      ref.read(filterWidgetControllerProvider.notifier).ages,
                      [selectedAgeIndex],
                      context,
                      (index) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .selectAge(index);
                      },
                    ),
                    gapH16,
                    _displayFilters(
                      AppStrings.categories.tr(),
                      ref
                          .read(filterWidgetControllerProvider.notifier)
                          .categories
                          .map((e) {
                            if (context.locale.languageCode == "en") {
                              return e.name ?? '';
                            } else {
                              return e.name ?? '';
                            }
                          })
                          .toList(),
                      [selectedCategoryIndex],
                      context,
                      (index) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .selectCategory(index);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16.0),
              child: FilledButton(
                onPressed: () {
                  ref.invalidate(searchProductsProvider);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    AppStrings.applyFilters.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            // clear filters
            gapH8,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ref
                      .read(filterWidgetControllerProvider.notifier)
                      .clearFilters();
                  ref.invalidate(searchProductsProvider);
                  Navigator.of(context).pop();
                },
                child: Text(
                  AppStrings.clearFilters.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _displayFilters(
  String filterTitle,
  List<String> filters,
  List<int> selectedFilters,
  BuildContext context,
  void Function(int) onTap,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        filterTitle,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      gapH8,
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filters.map((e) {
          bool isSelected = selectedFilters.contains(filters.indexOf(e));
          int index = filters.indexOf(e);
          return IntrinsicWidth(
            child: FilterChipWidget(
              text: e,
              isSelected: isSelected,
              onTap: () => onTap(index),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

class _PriceRangeWidget extends ConsumerStatefulWidget {
  final double? minPrice;
  final double? maxPrice;

  const _PriceRangeWidget({this.minPrice, this.maxPrice});

  @override
  ConsumerState<_PriceRangeWidget> createState() => _PriceRangeWidgetState();
}

class _PriceRangeWidgetState extends ConsumerState<_PriceRangeWidget> {
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.maxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.priceRange.tr(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        gapH8,
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.minPriceLabel.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  ref
                      .read(filterWidgetControllerProvider.notifier)
                      .setMinPrice(double.tryParse(value));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.maxPriceLabel.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  ref
                      .read(filterWidgetControllerProvider.notifier)
                      .setMaxPrice(double.tryParse(value));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
