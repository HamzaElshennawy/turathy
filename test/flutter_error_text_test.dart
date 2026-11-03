import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/helper/flutter_error_text.dart';

void main() {
  test('release-style details show the FlutterError summary, not the wrapper', () {
    final details = FlutterErrorDetails(
      exception: FlutterError('Cannot hit test. The widget has no size.'),
    );

    final text = readableFlutterError(details);

    expect(text, contains('Cannot hit test. The widget has no size.'));
    expect(text, isNot(contains("Instance of 'FlutterErrorDetails'")));
  });

  test('a nested details object is unwrapped to the original exception', () {
    final details = FlutterErrorDetails(
      exception: FlutterErrorDetails(
        exception: StateError('lot price missing'),
      ),
    );

    expect(readableFlutterError(details), contains('lot price missing'));
  });

  test('the stack is included when the framework captured one', () {
    final details = FlutterErrorDetails(
      exception: StateError('bid failed'),
      stack: StackTrace.fromString('#0 AuctionBiddingControlsWidget.build'),
    );

    final text = readableFlutterError(details);

    expect(text, contains('bid failed'));
    expect(text, contains('AuctionBiddingControlsWidget.build'));
  });
}
