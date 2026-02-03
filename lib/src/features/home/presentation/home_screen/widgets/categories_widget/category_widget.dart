import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/common_widgets/shimmer_widget/shimmer_widget.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../main_screen.dart';
import '../../../../../search/presentation/widgets/filter_widget/filter_widget_controller.dart';
import '../../../../../auctions/data/auctions_repository.dart';
import '../../../../data/category_repository.dart';

class CategoriesWidget extends ConsumerWidget {
  const CategoriesWidget({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final value = ref.watch(getAllCategoriesProvider);
    return value.when(
      data: (categories) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.categories.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            gapH8,
            SizedBox(
              height: 80,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => Card(
                        shape: const CircleBorder(),
                        elevation: 1,
                        shadowColor: Theme.of(context).colorScheme.primary,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            ref.read(pageControllerProvider).animateToPage(1,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn);
                            ref
                                .read(filterWidgetControllerProvider.notifier)
                                .selectCategory(index);
                            ref.invalidate(searchProductsProvider);
                          },
                          child: Container(
                            width: 80,
                            alignment: Alignment.bottomCenter,
                            decoration: ShapeDecoration(
                                shape: const CircleBorder(),
                                image: DecorationImage(
                                    image: NetworkImage(
                                        categories[index].picUrl ?? ''),
                                    fit: BoxFit.cover)),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.6),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(100)),
                                // borderRadius: const BorderRadius.vertical(
                                //     bottom: Radius.circular(8)),
                              ),
                              child: Text(
                                (context.locale == const Locale('ar')
                                        ? categories[index].name
                                        : categories[index].name) ??
                                    "",
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                              ),
                            ),
                          ),
                        ),
                      ),
                  separatorBuilder: (context, index) => gapW4,
                  itemCount: categories.length),
            )
          ],
        );
      },
      error: (error, stackTrace) => Text('Error: $error'),
      loading: () => const Column(
        children: [
          ShimmerWidget(
            width: 90,
            height: 20,
            containerShape: BoxShape.rectangle,
          ),
          gapH8,
          ShimmerWidget(
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }
}
