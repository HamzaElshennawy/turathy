import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

/// One titled rail or grid inside search results and the category hub.
class DiscoverySection extends StatelessWidget {
  const DiscoverySection({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
    this.sectionKey,
    this.grid = false,
    this.railHeight = 280,
  });

  final String title;
  final String emptyMessage;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Key? sectionKey;
  final bool grid;
  final double railHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: sectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        gapH8,
        if (itemCount == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else if (grid)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.52,
            ),
            itemBuilder: itemBuilder,
          )
        else
          SizedBox(
            height: railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (context, index) => gapW8,
              itemBuilder: itemBuilder,
            ),
          ),
        gapH20,
      ],
    );
  }
}
