/// {@category Components}
///
/// A generic UI utility for standardized handling of Riverpod [AsyncValue] states.
/// 
/// [AsyncValueWidget] eliminates boilerplate by centralizing the `when` logic 
/// used to switch between loading spinners, error messages, and successful data 
/// builders. This ensures a consistent 'Turathy' look-and-feel across all 
/// asynchronous data-driven screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_functions/app_functions.dart';
import 'error_message_widget.dart';
import 'logo_loading.dart';

/// A robust wrapper for [AsyncValue] that handles loading and error states automatically.
/// 
/// The widget provides:
/// - **Automatic Logging**: Errors and stack traces are piped to [AppFunctions.logPrint].
/// - **Standardized Loaders**: Defaults to [LogoLoading] if no custom loader is provided.
/// - **User-Friendly Errors**: Renders a dedicated [ErrorMessageWidget] on failure.
class AsyncValueWidget<T> extends StatelessWidget {
  /// The reactive source of data to be monitored.
  final AsyncValue<T> value;

  /// The UI builder to execute when [value] is successfully resolved.
  final Widget Function(T) data;

  /// Optional override for the loading state UI. 
  /// 
  /// If provided, this function is called when the state is 'loading'. 
  /// If null, a centered [LogoLoading] with a size of 40 is used.
  final Widget Function()? loading;

  /// Creates an [AsyncValueWidget] with the specified source and builders.
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: (error, stackTrace) {
        // Log details for developer diagnostics in console/sentry
        AppFunctions.logPrint(
          message: "AsyncValueWidget Error: ${error.toString()}\nStackTrace: ${stackTrace.toString()}",
        );
        // Render a centered, human-readable error snippet
        return Center(child: ErrorMessageWidget(error.toString()));
      },
      loading: loading ??
          () => const LogoLoading(
                size: 40,
              ),
    );
  }
}
