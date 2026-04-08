import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_locations/app_locations.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../core/helper/analytics/analytics_service.dart';
import '../../../../../core/helper/socket/socket_models.dart';
import '../../../../auctions/data/auctions_repository.dart';
import '../filter_chip_widget.dart';
import 'filter_widget_controller.dart';

class FilterWidget extends ConsumerWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterWidgetControllerProvider);
    final minPrice = filterState.minPrice;
    final maxPrice = filterState.maxPrice;

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
                    _displayFilters(
                      AppStrings.categories.tr(),
                      ref
                          .read(filterWidgetControllerProvider.notifier)
                          .categories
                          .map((e) => e.name ?? '')
                          .toList(),
                      [
                        ref
                            .watch(filterWidgetControllerProvider.notifier)
                            .selectedCategoryIndex,
                      ],
                      context,
                      (index) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .selectCategory(index);
                      },
                    ),
                    gapH16,
                    _RangeSliderWidget(
                      title: AppStrings.priceRange.tr(),
                      min: 0,
                      max: 10000,
                      divisions: 1000,
                      initialMinValue: minPrice,
                      initialMaxValue: maxPrice,
                      labelFormatter: (val) => val.toInt().toString(),
                      onChanged: (min, max) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .setMinPrice(min);
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .setMaxPrice(max);
                      },
                    ),
                    gapH16,
                    gapH16,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.country.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        gapH8,
                        DropdownButtonFormField<String>(
                          value: filterState.country?.isEmpty == true
                              ? null
                              : filterState.country,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          hint: Text(AppStrings.country.tr()),
                          items: [
                            DropdownMenuItem<String>(
                              value: '',
                              child: Text('all'.tr()),
                            ),
                            ...countries.map((c) {
                              final flag = SocketUser.getFlagEmoji(c.code);
                              final isAr = context.locale.languageCode == 'ar';
                              final name = isAr ? c.nameAr : c.nameEn;
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text('$flag  $name'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            ref
                                .read(filterWidgetControllerProvider.notifier)
                                .setCountry(value ?? '');
                          },
                        ),
                      ],
                    ),
                    gapH16,
                    _RangeSliderWidget(
                      title: AppStrings.dateRange.tr(),
                      min: 1700,
                      max: DateTime.now().year.toDouble(),
                      divisions: DateTime.now().year - 1700,
                      initialMinValue: filterState.dateFrom == -1
                          ? null
                          : filterState.dateFrom?.toDouble(),
                      initialMaxValue: filterState.dateTo == -1
                          ? null
                          : filterState.dateTo?.toDouble(),
                      labelFormatter: (val) => val.toInt().toString(),
                      onChanged: (min, max) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .setDateFrom(min.toInt());
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .setDateTo(max.toInt());
                      },
                    ),
                    gapH16,
                    _FilterTextFieldWidget(
                      label: AppStrings.denomination.tr(),
                      initialValue: filterState.denomination,
                      onChanged: (val) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .setDenomination(val);
                      },
                    ),
                    gapH16,
                    _displayFilters(
                      AppStrings.gradedStatus.tr(),
                      [AppStrings.graded.tr(), AppStrings.notGraded.tr()],
                      filterState.isGraded == true
                          ? [0]
                          : (filterState.isGraded == false ? [1] : []),
                      context,
                      (index) {
                        final currentValue = filterState.isGraded;
                        final newValue = index == 0;
                        if (currentValue == newValue) {
                          ref
                              .read(filterWidgetControllerProvider.notifier)
                              .setIsGraded(null);
                        } else {
                          ref
                              .read(filterWidgetControllerProvider.notifier)
                              .setIsGraded(newValue);
                        }
                      },
                    ),
                    if (filterState.isGraded == true) ...[
                      gapH16,
                      _displayFilters(
                        AppStrings.gradingCompany.tr(),
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .gradingCompanies,
                        [
                          ref
                              .watch(filterWidgetControllerProvider.notifier)
                              .selectedGradingCompanyIndex,
                        ],
                        context,
                        (index) {
                          ref
                              .read(filterWidgetControllerProvider.notifier)
                              .selectGradingCompany(index);
                        },
                      ),
                      gapH16,
                      _RangeTextFieldWidget(
                        title: AppStrings.gradeRange.tr(),
                        label1: AppStrings.gradeFrom.tr(),
                        label2: AppStrings.gradeTo.tr(),
                        initialValue1:
                            filterState.gradeFrom == -1 ? '' : filterState.gradeFrom?.toString(),
                        initialValue2:
                            filterState.gradeTo == -1 ? '' : filterState.gradeTo?.toString(),
                        keyboardType: TextInputType.number,
                        onChanged1: (val) {
                          ref
                              .read(filterWidgetControllerProvider.notifier)
                              .setGradeFrom(int.tryParse(val));
                        },
                        onChanged2: (val) {
                          ref
                              .read(filterWidgetControllerProvider.notifier)
                              .setGradeTo(int.tryParse(val));
                        },
                      ),
                    ],
                    gapH16,
                    _FilterTextFieldWidget(
                      label: AppStrings.metalType_.tr(),
                      initialValue: filterState.metalType,
                      onChanged: (val) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .setMetalType(val);
                      },
                    ),
                    gapH16,
                    _FilterTextFieldWidget(
                      label: AppStrings.metalFineness.tr(),
                      initialValue: filterState.metalFineness,
                      onChanged: (val) {
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .setMetalFineness(val);
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
                  String? selectedCategoryName;
                  for (final category
                      in ref.read(filterWidgetControllerProvider.notifier).categories) {
                    if (category.id == filterState.selectedCategoryID) {
                      selectedCategoryName = category.name;
                      break;
                    }
                  }

                  final activeFilterCount = [
                    filterState.selectedCategoryID != null &&
                        filterState.selectedCategoryID != -1,
                    minPrice != null,
                    maxPrice != null,
                    filterState.country != null && filterState.country!.isNotEmpty,
                    filterState.dateFrom != null && filterState.dateFrom != -1,
                    filterState.dateTo != null && filterState.dateTo != -1,
                    filterState.denomination != null &&
                        filterState.denomination!.isNotEmpty,
                    filterState.isGraded != null,
                    filterState.gradingCompany != null &&
                        filterState.gradingCompany!.isNotEmpty,
                    filterState.gradeFrom != null && filterState.gradeFrom != -1,
                    filterState.gradeTo != null && filterState.gradeTo != -1,
                    filterState.metalType != null &&
                        filterState.metalType!.isNotEmpty,
                    filterState.metalFineness != null &&
                        filterState.metalFineness!.isNotEmpty,
                  ].where((isActive) => isActive).length;

                  AnalyticsService.logFilterApplied(
                    category: selectedCategoryName,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    country: filterState.country,
                    isGraded: filterState.isGraded,
                    activeFilterCount: activeFilterCount,
                  );
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
          final isSelected = selectedFilters.contains(filters.indexOf(e));
          final index = filters.indexOf(e);
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

class _RangeSliderWidget extends ConsumerStatefulWidget {
  final String title;
  final double min;
  final double max;
  final int divisions;
  final String? Function(double) labelFormatter;
  final double? initialMinValue;
  final double? initialMaxValue;
  final void Function(double, double) onChanged;

  const _RangeSliderWidget({
    required this.title,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelFormatter,
    required this.initialMinValue,
    required this.initialMaxValue,
    required this.onChanged,
  });

  @override
  ConsumerState<_RangeSliderWidget> createState() => _RangeSliderWidgetState();
}

class _RangeSliderWidgetState extends ConsumerState<_RangeSliderWidget> {
  late RangeValues _currentRangeValues;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = RangeValues(
      widget.initialMinValue ?? widget.min,
      widget.initialMaxValue ?? widget.max,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${widget.labelFormatter(_currentRangeValues.start)} - ${widget.labelFormatter(_currentRangeValues.end)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        gapH8,
        RangeSlider(
          values: _currentRangeValues,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          labels: RangeLabels(
            widget.labelFormatter(_currentRangeValues.start) ?? '',
            widget.labelFormatter(_currentRangeValues.end) ?? '',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _currentRangeValues = values;
            });
          },
          onChangeEnd: (RangeValues values) {
            widget.onChanged(values.start, values.end);
          },
        ),
      ],
    );
  }
}

class _FilterTextFieldWidget extends ConsumerStatefulWidget {
  final String label;
  final String? initialValue;
  final void Function(String) onChanged;
  final TextInputType keyboardType;

  const _FilterTextFieldWidget({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  ConsumerState<_FilterTextFieldWidget> createState() =>
      _FilterTextFieldWidgetState();
}

class _FilterTextFieldWidgetState
    extends ConsumerState<_FilterTextFieldWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        gapH8,
        TextField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _RangeTextFieldWidget extends ConsumerStatefulWidget {
  final String title;
  final String label1;
  final String label2;
  final String? initialValue1;
  final String? initialValue2;
  final void Function(String) onChanged1;
  final void Function(String) onChanged2;
  final TextInputType keyboardType;

  const _RangeTextFieldWidget({
    required this.title,
    required this.label1,
    required this.label2,
    required this.initialValue1,
    required this.initialValue2,
    required this.onChanged1,
    required this.onChanged2,
    this.keyboardType = TextInputType.text,
  });

  @override
  ConsumerState<_RangeTextFieldWidget> createState() =>
      _RangeTextFieldWidgetState();
}

class _RangeTextFieldWidgetState extends ConsumerState<_RangeTextFieldWidget> {
  late final TextEditingController _controller1;
  late final TextEditingController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = TextEditingController(text: widget.initialValue1 ?? '');
    _controller2 = TextEditingController(text: widget.initialValue2 ?? '');
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
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
                controller: _controller1,
                keyboardType: widget.keyboardType,
                decoration: InputDecoration(
                  labelText: widget.label1,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: widget.onChanged1,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _controller2,
                keyboardType: widget.keyboardType,
                decoration: InputDecoration(
                  labelText: widget.label2,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: widget.onChanged2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
