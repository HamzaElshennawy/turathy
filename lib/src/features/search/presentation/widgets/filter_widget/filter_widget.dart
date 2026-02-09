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
    //final selectedColorIndex =
    //    ref.watch(filterWidgetControllerProvider.notifier).selectedColorIndex;
    //final selectedSizeIndex =
    //    ref.watch(filterWidgetControllerProvider.notifier).selectedSizeIndex;
    final selectedCategoryIndex = ref
        .watch(filterWidgetControllerProvider.notifier)
        .selectedCategoryIndex;
    //final isAllOffersSelected =
    //    ref.watch(filterWidgetControllerProvider).isAllOffersSelected;

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Text(
                  //   AppStrings.offers.tr(),
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w500,
                  //     color: Theme.of(context).colorScheme.onSurface,
                  //   ),
                  // ),
                  // gapH8,
                  // Wrap(spacing: 8, runSpacing: 8, children: [
                  //   FilterChipWidget(
                  //     text: AppStrings.allOffers.tr(),
                  //     isSelected: isAllOffersSelected,
                  //     onTap: () {
                  //       ref
                  //           .read(filterWidgetControllerProvider.notifier)
                  //           .selectAllOffers();
                  //     },
                  //   ),
                  // ]),
                  // gapH16,
                  // _displayFilters(
                  //     AppStrings.colors.tr(),
                  //     ref.read(filterWidgetControllerProvider.notifier).colors,
                  //     [selectedColorIndex],
                  //     context, (index) {
                  //   ref
                  //       .read(filterWidgetControllerProvider.notifier)
                  //       .selectColor(index);
                  // }),
                  // gapH16,
                  // _displayFilters(
                  //     AppStrings.sizes.tr(),
                  //     ref.read(filterWidgetControllerProvider.notifier).sizes,
                  //     [selectedSizeIndex],
                  //     context, (index) {
                  //   ref
                  //       .read(filterWidgetControllerProvider.notifier)
                  //       .selectSize(index);
                  // }),
                  // gapH16,
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
