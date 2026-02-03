import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/live_auction_screen.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/helper/socket/socket_exports.dart';
import '../../../authintication/presentation/sign_in_screen.dart';
import '../../domain/auction_model.dart';
import 'widgets/auction_images_slider_widget.dart';

class AuctionScreen extends ConsumerStatefulWidget {
  final AuctionModel auction;

  const AuctionScreen(this.auction, {super.key});

  @override
  ConsumerState<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends ConsumerState<AuctionScreen> {
  @override
  void initState() {
    ref.read(userCountUpdateProvider);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.auction.title ?? ''),
        centerTitle: true,
      ),
      floatingActionButton:
          // join now
          FloatingActionButton.extended(
            onPressed: () {
              if (CachedVariables.userId == null) {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => SignInScreen()));
                return;
              }
              // ref.read(socketHelperProvider).emitComment(widget.auction.id ?? 0, 45,
              //     'I am interested in this auction, please let me know the details');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LiveAuctionScreen(
                    auctionId: widget.auction.id ?? 0,
                    // todo change the admin based on the user id
                    isAdmin: widget.auction.userId == CachedVariables.userId,
                  ),
                ),
              );
            },
            label: Text(AppStrings.joinNow.tr()),
            icon: const Icon(Icons.insert_chart_outlined_rounded),
          ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuctionImagesSliderWidget(
                images: [widget.auction.imageUrl ?? ''],
                productID: widget.auction.id ?? 0,
              ),
              gapH8,
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (context.locale.languageCode == 'en'
                                    ? widget.auction.title
                                    : widget.auction.title) ??
                                '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          (context.locale.languageCode == 'en'
                                  ? widget.auction.category?.name
                                  : widget.auction.category?.name) ??
                              '',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                    gapH8,
                    if (widget.auction.description != null &&
                        widget.auction.description!.isNotEmpty) ...[
                      Text(
                        (context.locale.languageCode == 'en'
                                ? widget.auction.description
                                : widget.auction.description) ??
                            '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.6),
                        ),
                      ),
                      gapH8,
                    ],
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            //   children: [
                            //     Text(
                            //       AppStrings.price.tr(),
                            //       style: Theme.of(context)
                            //           .textTheme
                            //           .titleMedium
                            //           ?.copyWith(
                            //             color: Theme.of(context)
                            //                 .colorScheme
                            //                 .onSurface
                            //                 .withOpacity(.6),
                            //           ),
                            //     ),
                            //     Text(
                            //       auction.actualPrice.toString(),
                            //       style: Theme.of(context)
                            //           .textTheme
                            //           .titleMedium
                            //           ?.copyWith(
                            //             color: Theme.of(context).primaryColor,
                            //           ),
                            //     ),
                            //   ],
                            // ),
                            // gapH8,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.startedAt.tr(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withOpacity(.6),
                                      ),
                                ),
                                Text(
                                  DateFormat.yMMMMEEEEd(
                                    context.locale.languageCode,
                                  ).format(
                                    DateTime.parse(
                                      widget.auction.updatedAt ?? '',
                                    ),
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ],
                            ),
                            gapH8,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.endedAt.tr(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withOpacity(.6),
                                      ),
                                ),
                                Text(
                                  DateFormat.yMMMMEEEEd(
                                    context.locale.languageCode,
                                  ).format(
                                    DateTime.parse(
                                      widget.auction.expiryDate ?? '',
                                    ),
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ],
                            ),
                            gapH8,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppStrings.quantity.tr(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withOpacity(.6),
                                      ),
                                ),
                                Text(
                                  widget.auction.quantity.toString(),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    if (widget.auction.currentProduct != null &&
                        widget.auction.currentProduct!.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.currentProduct.tr(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.6),
                                ),
                          ),
                          Text(
                            widget.auction.currentProduct ?? '',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ],
                      ),
                      gapH8,
                    ],

                    // auction products
                    Text(
                      AppStrings.auctionProducts.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(
                      height: 135,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) => SizedBox(
                          width: 240,
                          child: Card(
                            child: ListTile(
                              title: Text(
                                widget
                                        .auction
                                        .auctionProducts?[index]
                                        .product ??
                                    '',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppStrings.price.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(.6),
                                            ),
                                      ),
                                      Text(
                                        widget
                                                .auction
                                                .auctionProducts?[index]
                                                .actualPrice
                                                .toString() ??
                                            '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                  gapH4,
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppStrings.minBidPrice.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(.6),
                                            ),
                                      ),
                                      Text(
                                        widget
                                                .auction
                                                .auctionProducts?[index]
                                                .minBidPrice
                                                .toString() ??
                                            '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                  gapH4,
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppStrings.bidPrice.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(.6),
                                            ),
                                      ),
                                      Text(
                                        widget
                                                .auction
                                                .auctionProducts?[index]
                                                .bidPrice
                                                .toString() ??
                                            '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        separatorBuilder: (context, index) => gapW8,
                        itemCount: widget.auction.auctionProducts?.length ?? 0,
                      ),
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(
                    //       AppStrings.minBidPrice.tr(),
                    //       style:
                    //           Theme.of(context).textTheme.titleMedium?.copyWith(
                    //                 color: Theme.of(context)
                    //                     .colorScheme
                    //                     .onSurface
                    //                     .withOpacity(.6),
                    //               ),
                    //     ),
                    //     Text(
                    //       auction.minBidPrice.toString() ?? '',
                    //       style:
                    //           Theme.of(context).textTheme.titleMedium?.copyWith(
                    //                 color: Theme.of(context).primaryColor,
                    //               ),
                    //     ),
                    //   ],
                    // ),
                    // gapH8,
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(
                    //       AppStrings.bidPrice.tr(),
                    //       style:
                    //           Theme.of(context).textTheme.titleMedium?.copyWith(
                    //                 color: Theme.of(context)
                    //                     .colorScheme
                    //                     .onSurface
                    //                     .withOpacity(.6),
                    //               ),
                    //     ),
                    //     Text(
                    //       auction.bidPrice.toString(),
                    //       style:
                    //           Theme.of(context).textTheme.titleMedium?.copyWith(
                    //                 color: Theme.of(context).primaryColor,
                    //               ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
