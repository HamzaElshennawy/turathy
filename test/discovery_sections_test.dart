import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/home/presentation/widgets/discovery_section.dart';

void main() {
  testWidgets('discovery feed shows current, upcoming, and store sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              DiscoverySection(
                sectionKey: const Key('discovery-current'),
                title: 'current',
                emptyMessage: 'no current',
                itemCount: 0,
                itemBuilder: (context, index) => const SizedBox(),
              ),
              DiscoverySection(
                sectionKey: const Key('discovery-upcoming'),
                title: 'upcoming',
                emptyMessage: 'no upcoming',
                itemCount: 1,
                itemBuilder: (context, index) => const Text('upcoming-lot'),
              ),
              DiscoverySection(
                sectionKey: const Key('discovery-store'),
                title: 'store',
                emptyMessage: 'no products',
                itemCount: 1,
                grid: true,
                itemBuilder: (context, index) => const Text('store-item'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('discovery-current')), findsOneWidget);
    expect(find.byKey(const Key('discovery-upcoming')), findsOneWidget);
    expect(find.byKey(const Key('discovery-store')), findsOneWidget);
    expect(find.text('no current'), findsOneWidget);
    expect(find.text('upcoming-lot'), findsOneWidget);
    expect(find.text('store-item'), findsOneWidget);
  });
}
