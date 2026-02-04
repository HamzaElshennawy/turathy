import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathi/src/features/home/presentation/home_screen/widgets/products_widget/products_list_widget.dart';
import 'package:turathi/src/features/home/presentation/home_screen/widgets/search_widget.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings/app_strings.dart';
import '../../../auctions/data/auctions_repository.dart';
import '../../../authintication/presentation/auth_controller.dart';
import '../../data/category_repository.dart';
import 'widgets/products_widget/live_auctions_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sizes.p8),
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authControllerProvider).valueOrNull;
              if (user == null) {
                return const SizedBox();
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '👋 ${AppStrings.hi.tr()}, ${user.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Consumer(
                builder: (context, ref, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchWidget(),
                      //CategoriesWidget(),
                      //gapH12,
                      LiveAuctionsWidget(),
                      //Expanded(child: OpenAuctionsWidget()),
                      ProductsListWidget(),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
