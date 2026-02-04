import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathi/src/core/constants/app_strings/app_strings.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppStrings.myOrders.tr()));
  }
}
