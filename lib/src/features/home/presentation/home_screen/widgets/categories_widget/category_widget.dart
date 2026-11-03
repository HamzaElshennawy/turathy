import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/common_widgets/shimmer_widget/shimmer_widget.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../../../../../../core/constants/app_strings/app_strings.dart';
import '../../../../../search/presentation/widgets/filter_widget/filter_widget_controller.dart';
import '../../../category_hub/category_hub_screen.dart';

import '../../../../data/category_repository.dart';

class CategoriesWidget extends ConsumerWidget {
  const CategoriesWidget({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final value = ref.watch(getAllCategoriesProvider);
    return value.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.categories.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              gapH8,
              Text(AppStrings.emptyCategories.tr()),
            ],
          );
        }
        final selectedCategoryId = ref
            .watch(filterWidgetControllerProvider)
            .selectedCategoryID;
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
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategoryId == category.id;
                  final imageUrl = category.picUrl;
                  return Card(
                    shape: const CircleBorder(),
                    elevation: 1,
                    shadowColor: Theme.of(context).colorScheme.primary,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        final id = category.id;
                        if (id == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.emptyCategories.tr()),
                            ),
                          );
                          return;
                        }
                        ref
                            .read(filterWidgetControllerProvider.notifier)
                            .selectCategoryById(id);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryHubScreen(
                              categoryId: id,
                              categoryName: category.localizedName(
                                context.locale.languageCode,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 80,
                        alignment: Alignment.bottomCenter,
                        decoration: ShapeDecoration(
                          shape: isSelected
                              ? CircleBorder(
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                )
                              : const CircleBorder(),
                          image: imageUrl != null && imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: imageUrl == null || imageUrl.isEmpty
                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                              : null,
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.8)
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.6),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(100),
                            ),
                          ),
                          child: Text(
                            category.localizedName(
                                    context.locale.languageCode),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) => gapW4,
                itemCount: categories.length,
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) =>
          Center(child: Text(AppStrings.checkInternetConnection.tr())),
      loading: () => const Column(
        children: [
          ShimmerWidget(
            width: 90,
            height: 20,
            containerShape: BoxShape.rectangle,
          ),
          gapH8,
          ShimmerWidget(width: 80, height: 80),
        ],
      ),
    );
  }
}
