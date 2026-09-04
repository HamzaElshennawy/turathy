import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/core/constants/app_functions/app_functions.dart';

void main() {
  testWidgets('zoom close X sits in AppBar and pops on both platforms',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _OpenZoomHarness()),
    );

    await tester.tap(find.text('open-zoom'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byKey(ZoomCloseButton.buttonKey), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(ZoomCloseButton.buttonKey),
        matching: find.byType(AppBar),
      ),
      findsOneWidget,
    );

    final button =
        tester.widget<IconButton>(find.byKey(ZoomCloseButton.buttonKey));
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('open-zoom'), findsOneWidget);
    expect(find.byKey(ZoomCloseButton.buttonKey), findsNothing);
  });
}

class _OpenZoomHarness extends StatelessWidget {
  const _OpenZoomHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () => AppFunctions.showImageDialog(
          context: context,
          imageUrl: 'https://example.invalid/zoom.png',
          id: 99,
        ),
        child: const Text('open-zoom'),
      ),
    );
  }
}
