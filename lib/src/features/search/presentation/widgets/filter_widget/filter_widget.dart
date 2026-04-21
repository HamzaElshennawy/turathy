// ignore_for_file: unused_element_parameter

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../core/helper/analytics/analytics_service.dart';
import '../../../data/filter_options_repository.dart';
import '../../../domain/filter_options_model.dart';
import '../filter_chip_widget.dart';
import 'filter_widget_controller.dart';

enum FilterContentType { auction, store }

class FilterWidget extends ConsumerWidget {
  final VoidCallback? onApply;
  final VoidCallback? onClear;
  final FilterContentType contentType;

  const FilterWidget({
    super.key,
    this.onApply,
    this.onClear,
    this.contentType = FilterContentType.auction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterWidgetControllerProvider);
    final optionsAsync = contentType == FilterContentType.store
        ? ref.watch(storeFilterOptionsProvider)
        : ref.watch(auctionFilterOptionsProvider);
    final options = optionsAsync.valueOrNull ?? const FilterOptionsModel();

    final minPrice = filterState.minPrice;
    final maxPrice = filterState.maxPrice;
    final priceMin = options.minPrice ?? 0;
    final priceMax =
        options.maxPrice != null && options.maxPrice! > priceMin ? options.maxPrice! : priceMin + 1000;
    final yearMin = (options.minYear ?? 1700).toDouble();
    final yearMax = (options.maxYear ?? DateTime.now().year).toDouble();
    final gradeMin = (options.minGrade ?? 1).toDouble();
    final gradeMax =
        options.maxGrade != null && options.maxGrade! > gradeMin ? options.maxGrade!.toDouble() : gradeMin + 1;

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
                    if (optionsAsync.isLoading && optionsAsync.valueOrNull == null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(),
                      ),
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
                      min: priceMin,
                      max: priceMax,
                      divisions: ((priceMax - priceMin).round()).clamp(1, 1000).toInt(),
                      initialMinValue: minPrice,
                      initialMaxValue: maxPrice,
                      labelFormatter: (val) => val.toInt().toString(),
                      onChanged: (min, max) {
                        ref.read(filterWidgetControllerProvider.notifier).setMinPrice(min);
                        ref.read(filterWidgetControllerProvider.notifier).setMaxPrice(max);
                      },
                    ),
                    gapH16,
                    _DropdownFilterField(
                      label: AppStrings.country.tr(),
                      value: filterState.country,
                      options: options.countries,
                      onChanged: (value) {
                        ref.read(filterWidgetControllerProvider.notifier).setCountry(value ?? '');
                      },
                    ),
                    gapH16,
                    _RangeSliderWidget(
                      title: AppStrings.dateRange.tr(),
                      min: yearMin,
                      max: yearMax > yearMin ? yearMax : yearMin + 1,
                      divisions: ((yearMax - yearMin).round()).clamp(1, 300).toInt(),
                      initialMinValue: filterState.dateFrom?.toDouble(),
                      initialMaxValue: filterState.dateTo?.toDouble(),
                      labelFormatter: (val) => val.toInt().toString(),
                      onChanged: (min, max) {
                        ref.read(filterWidgetControllerProvider.notifier).setDateFrom(min.toInt());
                        ref.read(filterWidgetControllerProvider.notifier).setDateTo(max.toInt());
                      },
                    ),
                    gapH16,
                    _DropdownFilterField(
                      label: AppStrings.itemType.tr(),
                      value: filterState.itemType,
                      options: options.itemTypes,
                      onChanged: (value) {
                        ref.read(filterWidgetControllerProvider.notifier).setItemType(value ?? '');
                      },
                    ),
                    gapH16,
                    _DropdownFilterField(
                      label: AppStrings.denomination.tr(),
                      value: filterState.denomination,
                      options: options.denominations,
                      onChanged: (value) {
                        ref.read(filterWidgetControllerProvider.notifier).setDenomination(value ?? '');
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
                          ref.read(filterWidgetControllerProvider.notifier).setIsGraded(null);
                        } else {
                          ref.read(filterWidgetControllerProvider.notifier).setIsGraded(newValue);
                        }
                      },
                    ),
                    if (filterState.isGraded == true) ...[
                      gapH16,
                      _displayFilters(
                        AppStrings.gradingCompany.tr(),
                        options.gradingCompanies,
                        filterState.gradingCompany == null
                            ? const []
                            : [
                                options.gradingCompanies.indexOf(filterState.gradingCompany!)
                              ].where((index) => index >= 0).toList(),
                        context,
                        (index) {
                          final selected = options.gradingCompanies[index];
                          ref.read(filterWidgetControllerProvider.notifier).setGradingCompany(
                                filterState.gradingCompany == selected ? '' : selected,
                              );
                        },
                      ),
                      gapH16,
                      _DropdownFilterField(
                        label: AppStrings.gradeDesignation.tr(),
                        value: filterState.gradeDesignation,
                        options: options.gradeDesignations,
                        onChanged: (value) {
                          ref.read(filterWidgetControllerProvider.notifier).setGradeDesignation(value ?? '');
                        },
                      ),
                      gapH16,
                      _RangeTextFieldWidget(
                        title: AppStrings.gradeRange.tr(),
                        label1: AppStrings.gradeFrom.tr(),
                        label2: AppStrings.gradeTo.tr(),
                        initialValue1: filterState.gradeFrom?.toString() ?? '',
                        initialValue2: filterState.gradeTo?.toString() ?? '',
                        helperText: '${gradeMin.toInt()} - ${gradeMax.toInt()}',
                        keyboardType: TextInputType.number,
                        onChanged1: (val) {
                          ref.read(filterWidgetControllerProvider.notifier).setGradeFrom(int.tryParse(val));
                        },
                        onChanged2: (val) {
                          ref.read(filterWidgetControllerProvider.notifier).setGradeTo(int.tryParse(val));
                        },
                      ),
                    ],
                    gapH16,
                    _DropdownFilterField(
                      label: AppStrings.metalType_.tr(),
                      value: filterState.metalType,
                      options: options.metalTypes,
                      onChanged: (value) {
                        ref.read(filterWidgetControllerProvider.notifier).setMetalType(value ?? '');
                      },
                    ),
                    gapH16,
                    _DropdownFilterField(
                      label: AppStrings.metalFineness.tr(),
                      value: filterState.metalFineness,
                      options: options.metalFinenessValues,
                      onChanged: (value) {
                        ref.read(filterWidgetControllerProvider.notifier).setMetalFineness(value ?? '');
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
                  for (final category in ref.read(filterWidgetControllerProvider.notifier).categories) {
                    if (category.id == filterState.selectedCategoryID) {
                      selectedCategoryName = category.name;
                      break;
                    }
                  }

                  final activeFilterCount = [
                    filterState.selectedCategoryID != null && filterState.selectedCategoryID != -1,
                    minPrice != null,
                    maxPrice != null,
                    filterState.country != null && filterState.country!.isNotEmpty,
                    filterState.dateFrom != null && filterState.dateTo != null,
                    filterState.itemType != null && filterState.itemType!.isNotEmpty,
                    filterState.denomination != null && filterState.denomination!.isNotEmpty,
                    filterState.isGraded != null,
                    filterState.gradingCompany != null && filterState.gradingCompany!.isNotEmpty,
                    filterState.gradeDesignation != null && filterState.gradeDesignation!.isNotEmpty,
                    filterState.gradeFrom != null,
                    filterState.gradeTo != null,
                    filterState.metalType != null && filterState.metalType!.isNotEmpty,
                    filterState.metalFineness != null && filterState.metalFineness!.isNotEmpty,
                  ].where((isActive) => isActive).length;

                  AnalyticsService.logFilterApplied(
                    category: selectedCategoryName,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    country: filterState.country,
                    isGraded: filterState.isGraded,
                    activeFilterCount: activeFilterCount,
                  );
                  onApply?.call();
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
                  ref.read(filterWidgetControllerProvider.notifier).clearFilters();
                  onClear?.call();
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

class _DropdownFilterField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownFilterField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        gapH8,
        DropdownButtonFormField<String>(
          value: value?.isEmpty == true ? null : value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          hint: Text(label),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text('all'.tr()),
            ),
            ...options.map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
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
    _currentRangeValues = _sanitizeRangeValues(
      widget.initialMinValue,
      widget.initialMaxValue,
    );
  }

  @override
  void didUpdateWidget(covariant _RangeSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.initialMinValue != widget.initialMinValue ||
        oldWidget.initialMaxValue != widget.initialMaxValue) {
      _currentRangeValues = _sanitizeRangeValues(
        widget.initialMinValue,
        widget.initialMaxValue,
      );
    }
  }

  RangeValues _sanitizeRangeValues(double? start, double? end) {
    final min = widget.min;
    final max = widget.max;

    final safeStart = (start ?? min).clamp(min, max).toDouble();
    final safeEnd = (end ?? max).clamp(min, max).toDouble();

    if (safeStart <= safeEnd) {
      return RangeValues(safeStart, safeEnd);
    }

    return RangeValues(safeEnd, safeStart);
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            valueIndicatorColor: Theme.of(context).colorScheme.primary,
            valueIndicatorTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: RangeSlider(
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
  final String? helperText;
  final void Function(String) onChanged1;
  final void Function(String) onChanged2;
  final TextInputType keyboardType;

  const _RangeTextFieldWidget({
    required this.title,
    required this.label1,
    required this.label2,
    required this.initialValue1,
    required this.initialValue2,
    this.helperText,
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
        if (widget.helperText != null) ...[
          Text(
            widget.helperText!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          gapH8,
        ],
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
