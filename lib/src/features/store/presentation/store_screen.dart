import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathi/src/core/constants/app_strings/app_strings.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppStrings.store.tr()));
  }
}
