import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'auctions_filter_provider.dart';

class AuctionsFilterWidget extends ConsumerWidget {
  const AuctionsFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(auctionsFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildFilterTab(
            context,
            ref,
            'future',
            AppStrings.futureAuctions.tr(),
            selectedFilter == 'future',
          ),
          gapW8,
          _buildFilterTab(
            context,
            ref,
            'current',
            AppStrings.currentAuctions.tr(),
            selectedFilter == 'current',
          ),
          gapW8,
          _buildFilterTab(
            context,
            ref,
            'ending_soon',
            AppStrings.endingSoonAuctions.tr(),
            selectedFilter == 'ending_soon',
          ), // Or 'all'
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context,
    WidgetRef ref,
    String filterKey,
    String label,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(auctionsFilterProvider.notifier).state = filterKey;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF005C29)
              : const Color(0xFFD0D5DD).withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
