import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/swipe_to_bid_bar.dart';

void main() {
  group('SwipeToBidBar.directedDelta', () {
    test('LTR: positive dx advances swipe', () {
      expect(
        SwipeToBidBar.directedDelta(12, TextDirection.ltr),
        12,
      );
    });

    test('LTR: negative dx retreats swipe', () {
      expect(
        SwipeToBidBar.directedDelta(-8, TextDirection.ltr),
        -8,
      );
    });

    test('RTL: swipe left (negative dx) advances swipe', () {
      // Arabic users drag the thumb from right toward left.
      expect(
        SwipeToBidBar.directedDelta(-15, TextDirection.rtl),
        15,
      );
    });

    test('RTL: swipe right (positive dx) retreats swipe', () {
      expect(
        SwipeToBidBar.directedDelta(10, TextDirection.rtl),
        -10,
      );
    });
  });

  testWidgets('RTL bar fires onConfirmed after horizontal drag left', (
    tester,
  ) async {
    var confirmed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: SwipeToBidBar(
                  amountText: '150',
                  hintText: 'اسحب للتأكيد',
                  somLabel: 'سوم',
                  onConfirmed: () => confirmed++,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final bar = find.byType(SwipeToBidBar);
    expect(bar, findsOneWidget);

    // Drag left across most of the bar (RTL confirm direction).
    await tester.drag(bar, const Offset(-260, 0));
    await tester.pump();
    expect(confirmed, 1);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('LTR bar fires onConfirmed after horizontal drag right', (
    tester,
  ) async {
    var confirmed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: SwipeToBidBar(
                  amountText: '40',
                  hintText: 'Swipe to confirm',
                  somLabel: 'Bid',
                  onConfirmed: () => confirmed++,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final bar = find.byType(SwipeToBidBar);
    await tester.drag(bar, const Offset(260, 0));
    await tester.pump();
    expect(confirmed, 1);
    await tester.pump(const Duration(milliseconds: 500));
  });

  test('thumbWidthFor grows for large bid amounts', () {
    final small = SwipeToBidBar.thumbWidthFor(
      somLabel: 'سوم',
      amountText: '40',
      maxTrackWidth: 360,
    );
    final large = SwipeToBidBar.thumbWidthFor(
      somLabel: 'سوم',
      amountText: '1260',
      maxTrackWidth: 360,
    );
    final huge = SwipeToBidBar.thumbWidthFor(
      somLabel: 'سوم',
      amountText: '125000',
      maxTrackWidth: 360,
    );
    expect(large, greaterThan(small));
    expect(huge, greaterThanOrEqualTo(large));
    expect(huge, lessThanOrEqualTo(228));
  });

  testWidgets('large amount 1260 stays fully visible (no ellipsis)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: SwipeToBidBar(
                  amountText: '1260',
                  hintText: 'اسحب للتأكيد',
                  somLabel: 'سوم',
                  onConfirmed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('1260'), findsOneWidget);
    expect(find.textContaining('سوم'), findsOneWidget);

    final amountText = tester.widget<Text>(
      find.text('سوم 1260'),
    );
    expect(amountText.overflow, isNull);

    // Drag partially — amount must still be fully painted.
    await tester.drag(find.byType(SwipeToBidBar), const Offset(-80, 0));
    await tester.pump();
    expect(find.text('سوم 1260'), findsOneWidget);

    final render = tester.renderObject<RenderParagraph>(
      find.text('سوم 1260'),
    );
    expect(render.didExceedMaxLines, isFalse);
  });

  testWidgets('success overlay shows no hint copy when successText is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeToBidBar(
            amountText: '10',
            hintText: 'اسحب للتأكيد',
            somLabel: 'سوم',
            showSuccess: true,
            onConfirmed: () {},
          ),
        ),
      ),
    );
    expect(find.text('اسحب للتأكيد'), findsNothing);
  });
}
