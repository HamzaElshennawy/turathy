import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/auctions/domain/auction_model.dart';
import '../../features/auctions/presentation/auction_screen/auction_screen.dart';
import '../constants/app_functions/app_functions.dart';
import '../constants/app_sizes.dart';

class AuctionCard extends StatelessWidget {
  final AuctionModel product;

  const AuctionCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Sizes.p8),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuctionScreen(product),
              ));
        },
        onLongPress: () {
          AppFunctions.showImageDialog(
              context: context,
              imageUrl: product.imageUrl ?? '',
              id: product.id ?? 0);
        },
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: product.id ?? 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Sizes.p8),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) => Center(
                          child: CircularProgressIndicator(
                              value: downloadProgress.progress),
                        ),
                      ),
                    ),
                  ),
                  if (product.expiryDate != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Sizes.p4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(Sizes.p8),
                            topLeft: Radius.circular(Sizes.p8),
                          ),
                        ),
                        child: Text(
                          'Ends in ${DateFormat.yMd().format(DateTime.parse(product.expiryDate!))}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              title: Text(
                (context.locale.languageCode == 'en'
                        ? product.title
                        : product.title) ??
                    '0',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                (context.locale.languageCode == 'en'
                        ? product.category?.name
                        : product.category?.name) ??
                    '0',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // style: Theme.of(context).textTheme.subtitleSmall,
              ),
            ),
          ],
        ),
      ),
    );
    // back: Card(
    //   child: Padding(
    //     padding: const EdgeInsets.all(Sizes.p4),
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //       // crossAxisAlignment: CrossAxisAlignment.stretch,
    //       children: [
    //         Text(
    //           product.nameEN,
    //           style: Theme.of(context).textTheme.titleMedium!.copyWith(
    //               fontWeight: FontWeight.bold,
    //               color: Theme.of(context).colorScheme.primary),
    //         ),
    //         const Text(
    //           'select quantity',
    //           style: TextStyle(
    //             fontSize: 15,
    //             fontWeight: FontWeight.bold,
    //           ),
    //           textAlign: TextAlign.center,
    //         ),
    //         Row(
    //           children: [
    //             IconButton(onPressed: () {}, icon: const Icon(Icons.remove)),
    //             Expanded(
    //                 child: TextField(
    //               controller: quantityController,
    //               textAlign: TextAlign.center,
    //               style: TextStyle(
    //                 fontSize: 15,
    //                 fontWeight: FontWeight.bold,
    //                 color: Theme.of(context).colorScheme.onSecondaryContainer,
    //               ),
    //               keyboardType: TextInputType.number,
    //             )),
    //             IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
    //           ],
    //         ),
    //         Consumer(
    //           builder: (BuildContext context, WidgetRef ref, Widget? child) {
    //             return PrimaryButton(
    //               isLoading: false,
    //               onPressed: () {
    //                 if (quantityController.text.isEmpty) return;
    //                 ref.read(cartControllerProvider.notifier).addProduct(
    //                     product, int.parse(quantityController.text));
    //               },
    //               text: 'Add to cart',
    //             );
    //           },
    //         )
    //       ],
    //     ),
    //   ),
    // ),
  }
}
