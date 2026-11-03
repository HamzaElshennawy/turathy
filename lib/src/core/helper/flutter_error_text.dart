import 'package:flutter/foundation.dart';

/// Release-safe text for the red error screen.
///
/// [FlutterErrorDetails.toString] calls [DiagnosticsNode.toStringDeep], which
/// is empty once asserts are stripped. That is why a release build showed
/// `Instance of 'FlutterErrorDetails'` instead of the widget that failed.
String readableFlutterError(FlutterErrorDetails details) {
  final buffer = StringBuffer();
  _writeException(buffer, details.exception, 0);
  final stack = details.stack?.toString().trim();
  if (stack != null && stack.isNotEmpty) {
    if (buffer.isNotEmpty) buffer.writeln();
    buffer.writeln(stack);
  }
  final text = buffer.toString().trim();
  if (text.isEmpty) return 'An unexpected error occurred.';
  return text;
}

void _writeException(StringBuffer buffer, Object exception, int depth) {
  if (depth > 4) {
    buffer.writeln(exception.runtimeType);
    return;
  }
  if (exception is FlutterErrorDetails) {
    _writeException(buffer, exception.exception, depth + 1);
    return;
  }
  if (exception is FlutterError) {
    for (final DiagnosticsNode node in exception.diagnostics) {
      final line = _nodeText(node);
      if (line.isNotEmpty) buffer.writeln(line);
    }
    return;
  }
  buffer.writeln('$exception');
}

String _nodeText(DiagnosticsNode node) {
  final value = node.value;
  if (value is List) {
    return value.map((Object? part) => '$part').join().trim();
  }
  if (value == null) return '';
  final text = '$value'.trim();
  if (text.startsWith('Instance of ')) return '';
  return text;
}
