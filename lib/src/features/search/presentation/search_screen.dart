import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/analytics/analytics_service.dart';

import '../../../core/common_widgets/white_rounded_text_form_field.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../auctions/data/auctions_repository.dart';
import 'widgets/bottom_sheet_widget.dart';
import 'widgets/filter_widget/filter_widget.dart';
import 'widgets/filter_widget/filter_widget_controller.dart';
import 'widgets/search_list_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'search_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Text(
                AppStrings.searchAuctions.tr(),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Consumer(builder: (context, ref, child) {
              final filterWidgetController =
                  ref.watch(filterWidgetControllerProvider);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.auctionType.tr()),
                    ChoiceChip(
                        label: Text(AppStrings.liveAuctions.tr()),
                        selected: filterWidgetController.isLiveAuctionsSelected,
                        onSelected: (value) {
                          ref
                              .read(filterWidgetControllerProvider.notifier)
                              .setIsLiveAuctionsSelected(value);
                          ref.invalidate(searchProductsProvider);
                        }),
                    ChoiceChip(
                        label: Text(AppStrings.openAuctions.tr()),
                        selected:
                            !filterWidgetController.isLiveAuctionsSelected,
                        onSelected: (value) {
                          ref
                              .read(filterWidgetControllerProvider.notifier)
                              .setIsLiveAuctionsSelected(!value);
                          ref.invalidate(searchProductsProvider);
                        }),
                    // Switch(
                    //   value: filterWidgetController.isLiveAuctionsSelected,
                    //   onChanged: (value) {
                    //     ref
                    //         .read(filterWidgetControllerProvider.notifier)
                    //         .setIsLiveAuctionsSelected(value);
                    //     ref.invalidate(searchProductsProvider);
                    //   },
                    // ),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Consumer(builder: (context, ref, child) {
                      return WhiteRoundedTextFormField(
                        readOnly: true,
                        controller: ref
                            .read(filterWidgetControllerProvider.notifier)
                            .searchController,
                        onChanged: (p0) {
                          if (p0.isEmpty) {
                            ref
                                .read(filterWidgetControllerProvider.notifier)
                                .setSearchText('');
                            ref.invalidate(searchProductsProvider);
                            return;
                          } else if (p0.length > 2) {
                            ref
                                .read(filterWidgetControllerProvider.notifier)
                                .setSearchText(p0);
                            ref.invalidate(searchProductsProvider);
                          }
                        },
                        validator: (p0) {
                          return null;
                        },
                        onFieldSubmitted: (p0) {
                          ref
                              .read(filterWidgetControllerProvider.notifier)
                              .setSearchText(p0);
                          ref.invalidate(searchProductsProvider);
                        },
                        keyboardType: TextInputType.text,
                        hintText: AppStrings.searchAuctions.tr(),
                        prefixIcon: const Icon(Icons.search),
                      );
                    }),
                  ),
                  gapW8,
                  Consumer(
                    builder: (context, ref, child) {
                      return IconButton.outlined(
                        constraints: const BoxConstraints(
                          minHeight: 60,
                          minWidth: 60,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (context) => BottomSheetWidget(
                              title: AppStrings.filters.tr(),
                              child: const FilterWidget(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.filter_alt_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                        style: IconButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Expanded(
              child: SearchListWidget(),
            ),
          ],
        ),
      ),
    );
  }
}


