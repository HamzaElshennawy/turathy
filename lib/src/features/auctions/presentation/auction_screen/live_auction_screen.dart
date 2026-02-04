import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathi/src/core/common_widgets/async_value_widget.dart';
import 'package:turathi/src/core/constants/app_images/app_images.dart';
import 'package:turathi/src/core/constants/app_sizes.dart';
import 'package:turathi/src/features/auctions/data/auctions_repository.dart';
import 'package:turathi/src/features/auctions/domain/auction_model.dart';
import 'package:turathi/src/features/auctions/presentation/auction_screen/widgets/agora_video_widget/agora_video_widget.dart';
import 'package:turathi/src/features/auctions/presentation/auction_screen/widgets/comment_section_widget.dart';
import 'package:turathi/src/features/auctions/presentation/auction_screen/widgets/gradient_chip_widget.dart';

import '../../../../core/helper/cache/cached_variables.dart';
import '../../../../core/helper/socket/socket_exports.dart';
import 'widgets/auction_images_slider_widget.dart';

class LiveAuctionScreen extends ConsumerStatefulWidget {
  final int auctionId;
  final bool isAdmin;

  const LiveAuctionScreen({
    required this.auctionId,
    this.isAdmin = false,
    super.key,
  });

  @override
  ConsumerState createState() => _LiveAuctionScreenState();
}

class _LiveAuctionScreenState extends ConsumerState<LiveAuctionScreen> {
  late SocketActions socketActions = ref.read(socketActionsProvider);
  late AuctionModel auction;
  RtcEngine? _engine; // Engine instance received from AgoraVideoWidget

  @override
  void initState() {
    if (widget.isAdmin) {
      socketActions.startLiveAuction(widget.auctionId, CachedVariables.userId!);
    }
    socketActions.joinAuction(widget.auctionId, CachedVariables.userId!);
    super.initState();
  }

  @override
  void dispose() {
    socketActions.leaveAuction(widget.auctionId, CachedVariables.userId!);
    super.dispose();
  }

  void _placeBid(int quantity, num currentBid, {bool isMinBid = false}) {
    final lastAuctionProduct = ref.read(auctionProductChangeProvider);
    if (currentBid == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (currentBid ==
            (lastAuctionProduct?.minBidPrice ?? auction.minBidPrice) &&
        isMinBid) {
      socketActions.placeBid(
        auction.id ?? 0,
        CachedVariables.userId!,
        (currentBid).toDouble(),
      );
      Navigator.of(context).pop();
      return;
    }
    socketActions.placeBid(
      auction.id ?? 0,
      CachedVariables.userId!,
      (currentBid +
              ((lastAuctionProduct?.bidPrice ?? auction.bidPrice!) * quantity))
          .toDouble(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userCountUpdateProvider, (previous, next) {});
    ref.listen(auctionEndedProvider, (previous, next) {
      // first empty invalidate the auction details provider and empty the value the of the change product provider
      ref.invalidate(auctionDetailsProvider(widget.auctionId));

      // Reset both the bid and product change streams completely to clear cached values
      resetProductChangeStream(ref);
      resetNewBidStream(ref);

      // show dialog with the winner based on the auction ended next value
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('المزاد انتهى'),
            content: Text('الفائز هو ${next.valueOrNull?.winnerName}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('حسنا'),
              ),
            ],
          );
        },
      );
    });
    final auctionValue = ref.watch(auctionDetailsProvider(widget.auctionId));
    auction = auctionValue.valueOrNull ?? AuctionModel(isLiveAuction: true);
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context1) {
              final lastAuctionProduct = ref.read(auctionProductChangeProvider);
              return widget.isAdmin
                  ? CupertinoActionSheet(
                      title: Text(
                        'هل تريد ترسية المزاد؟',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      actions: [
                        CupertinoActionSheetAction(
                          onPressed: () {
                            socketActions.awardAuction(
                              auction.id ?? 0,
                              CachedVariables.userId!,
                              lastAuctionProduct?.product ??
                                  auctionValue.value?.currentProduct ??
                                  '',
                            );
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'ترسية المزاد',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                        // emit cancel auction
                        // CupertinoActionSheetAction(
                        //   isDestructiveAction: true,
                        //   onPressed: () {
                        //     socketActions.cancelAuction(
                        //         auction.id ?? 0, CachedVariables.userId!);
                        //     Navigator.of(context).pop();
                        //   },
                        //   child: const Text(
                        //     'إلغاء المزاد',
                        //   ),
                        // ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('إلغاء'),
                      ),
                    )
                  : Consumer(
                      builder: (context, ref, child) {
                        final bidValue = ref.watch(currentBidStateProvider);
                        final num currentBid;
                        if ((auctionValue
                                    .valueOrNull
                                    ?.auctionBids
                                    ?.isNotEmpty ??
                                false) ||
                            bidValue != null) {
                          currentBid =
                              (bidValue?.bid ??
                              auctionValue
                                  .valueOrNull
                                  ?.auctionBids
                                  ?.first
                                  .bid)!;
                        } else {
                          currentBid = 0;
                        }

                        return CupertinoActionSheet(
                          title: Text(
                            currentBid == 0
                                ? (lastAuctionProduct?.minBidPrice ??
                                              auctionValue
                                                  .value
                                                  ?.minBidPrice) ==
                                          0
                                      ? 'المزاد لم يبدأ بعد'
                                      : 'هل تريد البدء بالمزايدة؟'
                                : 'زيادة السوم بكم؟',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          actions: currentBid == 0
                              ? (lastAuctionProduct?.minBidPrice ??
                                            auctionValue.value?.minBidPrice) ==
                                        0
                                    ? []
                                    : [
                                        CupertinoActionSheetAction(
                                          onPressed: () {
                                            _placeBid(
                                              1,
                                              (lastAuctionProduct
                                                          ?.minBidPrice ??
                                                      auctionValue
                                                          .value
                                                          ?.minBidPrice) ??
                                                  0,
                                              isMinBid: true,
                                            );
                                          },
                                          child: Text(
                                            'بدء المزايدة ب ${(lastAuctionProduct?.minBidPrice ?? auctionValue.valueOrNull?.minBidPrice)} ر.س',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                          ),
                                        ),
                                      ]
                              : [
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      _placeBid(1, currentBid);
                                    },
                                    child: Text(
                                      'زد بواحد فرق سوم (${(lastAuctionProduct?.bidPrice ?? auctionValue.valueOrNull?.bidPrice)})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      _placeBid(2, currentBid);
                                    },
                                    child: Text(
                                      'زد باثنين فرق سوم (${((lastAuctionProduct?.bidPrice ?? auctionValue.valueOrNull?.bidPrice) ?? 0) * 2})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      _placeBid(3, currentBid);
                                    },
                                    child: Text(
                                      'زد بثلاثة فرق سوم (${((lastAuctionProduct?.bidPrice ?? auctionValue.valueOrNull?.bidPrice) ?? 0) * 3})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('إلغاء'),
                          ),
                        );
                      },
                    );
            },
          );
        },
        backgroundColor: Colors.white,
        child: Image.asset(AppImages.logo, height: 35),
      ),
      body: SafeArea(
        child: AsyncValueWidget(
          value: auctionValue,
          data: (auction) {
            return Stack(
              children: [
                if (auction.isLiveAuction)
                  Consumer(
                    builder: (context, ref, child) {
                      final agoraTokenValue = ref.watch(
                        agoraTokenProvider(
                          AgoraTokenRequest(
                            auctionID: widget.auctionId,
                            isPublisher: widget.isAdmin,
                          ),
                        ),
                      );
                      return AsyncValueWidget(
                        value: agoraTokenValue,
                        data: (token) => AgoraVideoWidget(
                          isAdmin: widget.isAdmin,
                          agoraToken: token,
                          auctionId: widget.auctionId,
                          onEngineInitialized: (engine) {
                            _engine = engine;
                          },
                        ),
                      );
                    },
                  ),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: const ShapeDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black87],
                              ),
                              shape: StadiumBorder(),
                            ),
                            child: ListTile(
                              textColor: Colors.white,
                              leading: Container(
                                height: 50,
                                width: 50,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(AppImages.logo),
                                ),
                              ),
                              title: Text(auction.user?.name ?? ''),
                              subtitle: Consumer(
                                builder: (context, ref, child) {
                                  final userCount = ref.watch(
                                    userCountUpdateProvider,
                                  );
                                  return userCount.when(
                                    data: (data) =>
                                        Text('${data.userCount} مشاهد'),
                                    error: (error, stack) =>
                                        const Text('... مشاهد'),
                                    loading: () => const Text('... مشاهد'),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // change product button as opening dialogue with 4 inputs for product name, min bid price, bid price, and actualPrice
                        if (widget.isAdmin) ...[
                          IconButton(
                            color: Colors.black,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              showGeneralDialog(
                                context: context,
                                pageBuilder: (context, animation, secondaryAnimation) {
                                  final lastProductValues = ref.read(
                                    auctionProductChangeProvider,
                                  );
                                  final formKey = GlobalKey<FormState>();

                                  // FocusNodes for each field
                                  final productNameFocusNode = FocusNode();

                                  final productNameController =
                                      TextEditingController(
                                        text:
                                            lastProductValues?.product ??
                                            auction.currentProduct,
                                      );
                                  final minBidPriceController =
                                      TextEditingController(
                                        text:
                                            lastProductValues?.minBidPrice
                                                .toString() ??
                                            auction.minBidPrice.toString(),
                                      );
                                  final bidPriceController =
                                      TextEditingController(
                                        text:
                                            lastProductValues?.bidPrice
                                                .toString() ??
                                            auction.bidPrice.toString(),
                                      );
                                  final actualPriceController =
                                      TextEditingController(
                                        text:
                                            lastProductValues?.actualPrice
                                                .toString() ??
                                            auction.actualPrice.toString(),
                                      );

                                  // Auto-focus on first field
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    productNameFocusNode.requestFocus();
                                    productNameController.selection =
                                        TextSelection(
                                          baseOffset: 0,
                                          extentOffset:
                                              productNameController.text.length,
                                        );
                                  });

                                  return AlertDialog(
                                    title: const Text('تغيير السلعة'),
                                    content: Form(
                                      key: formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'اسم السلعة',
                                            ),
                                            controller: productNameController,
                                            focusNode: productNameFocusNode,
                                            textInputAction:
                                                TextInputAction.next,
                                            onFieldSubmitted: (_) {
                                              minBidPriceController.selection =
                                                  TextSelection(
                                                    baseOffset: 0,
                                                    extentOffset:
                                                        minBidPriceController
                                                            .text
                                                            .length,
                                                  );
                                            },
                                          ),
                                          TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'فتح الباب',
                                            ),
                                            controller: minBidPriceController,
                                            textInputAction:
                                                TextInputAction.next,
                                            keyboardType: TextInputType.number,
                                            onFieldSubmitted: (_) {
                                              bidPriceController
                                                  .selection = TextSelection(
                                                baseOffset: 0,
                                                extentOffset: bidPriceController
                                                    .text
                                                    .length,
                                              );
                                            },
                                          ),
                                          TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'فرق السوم',
                                            ),
                                            controller: bidPriceController,
                                            textInputAction:
                                                TextInputAction.next,
                                            keyboardType: TextInputType.number,
                                            onFieldSubmitted: (_) {
                                              actualPriceController.selection =
                                                  TextSelection(
                                                    baseOffset: 0,
                                                    extentOffset:
                                                        actualPriceController
                                                            .text
                                                            .length,
                                                  );
                                            },
                                          ),
                                          TextFormField(
                                            decoration: const InputDecoration(
                                              labelText: 'حد السوم',
                                            ),
                                            controller: actualPriceController,
                                            textInputAction:
                                                TextInputAction.done,
                                            keyboardType: TextInputType.number,
                                            onFieldSubmitted: (_) async {
                                              // Submit form on last field
                                              if (formKey.currentState
                                                      ?.validate() ??
                                                  false) {
                                                socketActions
                                                    .changeCurrentProduct(
                                                      auctionId:
                                                          auction.id ?? 0,
                                                      product:
                                                          productNameController
                                                              .text,
                                                      minBidPrice: double.parse(
                                                        minBidPriceController
                                                            .text,
                                                      ),
                                                      bidPrice: double.parse(
                                                        bidPriceController.text,
                                                      ),
                                                      actualPrice: double.parse(
                                                        actualPriceController
                                                            .text,
                                                      ),
                                                    );
                                                Navigator.of(context).pop();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('إلغاء'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (formKey.currentState
                                                  ?.validate() ??
                                              false) {
                                            socketActions.changeCurrentProduct(
                                              auctionId: auction.id ?? 0,
                                              product:
                                                  productNameController.text,
                                              minBidPrice: double.parse(
                                                minBidPriceController.text,
                                              ),
                                              bidPrice: double.parse(
                                                bidPriceController.text,
                                              ),
                                              actualPrice: double.parse(
                                                actualPriceController.text,
                                              ),
                                            );
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        child: const Text('حفظ'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          if (auction.isLiveAuction)
                            InkWell(
                              onTap: () async {
                                if (_engine != null) {
                                  await _engine!.switchCamera();
                                }
                              },
                              child: Icon(
                                Icons.camera_front,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                        IconButton(
                          color: Colors.black,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    if (!auction.isLiveAuction)
                      AuctionImagesSliderWidget(
                        images: auction.auctionImages ?? [],
                        productID: auction.id ?? 0,
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final bidValue = ref.watch(
                                currentBidStateProvider,
                              );
                              return ((auction.auctionBids?.isNotEmpty ??
                                          false) ||
                                      bidValue != null)
                                  ? Column(
                                      children: [
                                        GradientChipWidget(
                                          text:
                                              bidValue?.user?.name ??
                                              ((auction
                                                          .auctionBids
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? auction
                                                            .auctionBids
                                                            ?.first
                                                            .user
                                                            ?.name ??
                                                        '...'
                                                  : '...'),
                                          color: Colors.amber.shade700,
                                          icon: const Icon(
                                            Icons.celebration,
                                            color: Colors.white,
                                          ),
                                        ),
                                        // bid bid amount
                                        GradientChipWidget(
                                          text:
                                              '${bidValue?.bid ?? ((auction.auctionBids?.isNotEmpty ?? false) ? auction.auctionBids?.first.bid : 0)} ريال سعودي',
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          icon: const Icon(
                                            Icons.monetization_on,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : GradientChipWidget(
                                      text: 'كن اول المزايدين',
                                      color: Colors.amber.shade700,
                                    );
                            },
                          ),
                        ),
                        gapW8,
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final auctionChangeProduct = ref.watch(
                                auctionProductChangeProvider,
                              );
                              ref.listen(auctionProductChangeProvider, (
                                previous,
                                next,
                              ) {
                                print('previous: $previous');
                                print('next: $next');
                              });
                              return Column(
                                children: [
                                  GradientChipWidget(
                                    text:
                                        'اسم السلعة: ${auctionChangeProduct?.product ?? auction.currentProduct}',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    isReversed: true,
                                  ),
                                  // فتح الباب
                                  GradientChipWidget(
                                    text:
                                        'فتح الباب: ${auctionChangeProduct?.minBidPrice ?? auction.minBidPrice} ر.س',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    isReversed: true,
                                  ),
                                  // فرق السوم
                                  GradientChipWidget(
                                    text:
                                        'فرق السوم: ${auctionChangeProduct?.bidPrice ?? auction.bidPrice} ر.س',
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    isReversed: true,
                                  ),
                                  if (widget.isAdmin)
                                    // حد السوم
                                    GradientChipWidget(
                                      text:
                                          'حد السوم: ${auctionChangeProduct?.actualPrice ?? auction.actualPrice} ر.س',
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      isReversed: true,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    gapH12,
                    Expanded(child: CommentsSectionWidget(auction)),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
