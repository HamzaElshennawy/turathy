import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathi/src/core/constants/app_strings/app_strings.dart';

class SearchWidget extends StatelessWidget {
  const SearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search Bar
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade400,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    //textAlign: TextAlign.right, // Assuming RTL based on "ابحث"
                    decoration: InputDecoration(
                      hintText: AppStrings.search.tr(),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Filter Button
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              // TODO: Implement filter action
            },
            icon: Icon(
              Icons.tune_rounded, // Better match for filter icon
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
