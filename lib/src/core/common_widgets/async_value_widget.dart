import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_functions/app_functions.dart';
import 'error_message_widget.dart';
import 'logo_loading.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final Widget Function()? loading;

  const AsyncValueWidget(
      {super.key, required this.value, required this.data, this.loading});

  @override
  Widget build(BuildContext context) {
    return value.when(
        data: data,
        error: (error, stackTrace) {
          AppFunctions.logPrint(
              message: error.toString() + stackTrace.toString());
          return Center(child: ErrorMessageWidget(error.toString()));
        },
        loading: loading ??
            () => const LogoLoading(
                  size: 40,
                ));
  }
}
