/// {@category Components}
///
/// A standardized UI component for displaying failure messages.
/// 
/// [ErrorMessageWidget] ensures that any runtime or network error is presented 
/// with consistent typography and color (bold red). It is primarily used as 
/// the 'error' builder in [AsyncValueWidget].
library;

import 'package:flutter/material.dart';

/// A persistent, high-visibility text widget for identifying errors.
class ErrorMessageWidget extends StatelessWidget {
  /// The human-readable or technical description of the failure.
  final String errorMessage;

  /// Creates an [ErrorMessageWidget] with the provided [errorMessage].
  const ErrorMessageWidget(this.errorMessage, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      errorMessage,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
