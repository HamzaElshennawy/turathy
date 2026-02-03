import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';

import '../../../../core/common_widgets/auction_card.dart';
import '../../../../core/common_widgets/shimmer_widget/shimmer_widget.dart';
import '../../../../core/common_widgets/winning_auction_card.dart';
import '../../../../core/constants/app_functions/app_functions.dart';
import '../../../../core/constants/app_strings/app_strings.dart';

class UserAuctionsScreen extends ConsumerStatefulWidget {
  const UserAuctionsScreen({super.key});

  @override
  ConsumerState<UserAuctionsScreen> createState() => _UserAuctionsScreenState();
}

class _UserAuctionsScreenState extends ConsumerState<UserAuctionsScreen>
    with SingleTickerProviderStateMixin {
  String auctionType = 'Open';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.myAuctions.tr(), style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: AppStrings.myAuctions.tr()),
              Tab(text: AppStrings.winningAuctions.tr()),
            ],
            labelStyle: Theme.of(context).textTheme.titleMedium,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CurrentAuctionsTab(auctionType: auctionType),
              _WinningAuctionsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentAuctionsTab extends ConsumerStatefulWidget {
  final String auctionType;

  const _CurrentAuctionsTab({required this.auctionType});

  @override
  ConsumerState<_CurrentAuctionsTab> createState() =>
      _CurrentAuctionsTabState();
}

class _CurrentAuctionsTabState extends ConsumerState<_CurrentAuctionsTab> {
  late String auctionType;

  @override
  void initState() {
    super.initState();
    auctionType = widget.auctionType;
  }

  @override
  Widget build(BuildContext context) {
    final userAuctionValue = ref.watch(userAuctionsProvider(auctionType));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  AppStrings.auctionType.tr(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: Text(AppStrings.liveAuctions.tr()),
                selected: auctionType == 'Live',
                onSelected: (value) {
                  setState(() {
                    auctionType = 'Live';
                  });
                  ref.invalidate(userAuctionsProvider(auctionType));
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(AppStrings.openAuctions.tr()),
                selected: auctionType == 'Open',
                onSelected: (value) {
                  setState(() {
                    auctionType = 'Open';
                  });
                  ref.invalidate(userAuctionsProvider(auctionType));
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: userAuctionValue.when(
            data: (data) {
              if (data.isEmpty) {
                return Center(child: Text(AppStrings.noThingFound.tr()));
              }
              return ListView.builder(
                itemExtent: 300,
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  final product = data[index];
                  return AuctionCard(product: product);
                },
              );
            },
            loading: () => GridView.builder(
              shrinkWrap: true,
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppFunctions.isMobile(context: context) ? 2 : 3,
                childAspectRatio: .7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) =>
                  const ShimmerWidget(width: 400, height: 0),
            ),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }
}

class _WinningAuctionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winningAuctionsValue = ref.watch(userWinningAuctionsProvider);

    return winningAuctionsValue.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(child: Text(AppStrings.noThingFound.tr()));
        }
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (BuildContext context, int index) {
            final winningAuction = data[index];
            return WinningAuctionCard(winningAuction: winningAuction);
          },
        );
      },
      loading: () => GridView.builder(
        shrinkWrap: true,
        itemCount: 4,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: AppFunctions.isMobile(context: context) ? 2 : 3,
          childAspectRatio: .7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) =>
            const ShimmerWidget(width: 400, height: 0),
      ),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }
}
