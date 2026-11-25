import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bids_history_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CachedVariables.userId = 7;
  });

  tearDown(() {
    CachedVariables.userId = null;
  });

  testWidgets('public history collapses equal amounts and keeps distinct prices', (
    tester,
  ) async {
    await EasyLocalization.ensureInitialized();
    await _show(tester, 'BCA362', [
      _bid(
        id: 11,
        userId: 80,
        amount: 110,
        nickname: 'IIC757',
        createdAt: '2026-11-25T17:30:00Z',
      ),
      _bid(
        id: 12,
        userId: 326,
        amount: 110,
        nickname: 'BCA362',
        createdAt: '2026-11-25T17:38:00Z',
      ),
    ]);
    expect(find.text('110 '), findsOneWidget);
    expect(find.text('BCA362'), findsOneWidget);
    expect(find.text('IIC757'), findsNothing);

    await _show(tester, '100 ', [
      _bid(
        id: 10,
        userId: 326,
        amount: 100,
        nickname: 'BCA362',
        createdAt: '2026-11-25T16:12:00Z',
      ),
      _bid(
        id: 12,
        userId: 326,
        amount: 110,
        nickname: 'BCA362',
        createdAt: '2026-11-25T17:38:00Z',
      ),
    ]);
    expect(find.text('100 '), findsOneWidget);
    expect(find.text('110 '), findsOneWidget);

    await _show(tester, '200 ', [
      _bid(
        id: 12,
        userId: 326,
        amount: 110,
        nickname: 'BCA362',
        createdAt: '2026-11-25T17:38:00Z',
      ),
      _bid(
        id: 13,
        userId: 7,
        amount: 110,
        nickname: 'ME',
        createdAt: '2026-11-25T17:40:00Z',
        isActive: false,
      ),
      _bid(
        id: 14,
        userId: 7,
        amount: 200,
        nickname: 'ME',
        createdAt: '2026-11-25T17:41:00Z',
        isActive: false,
      ),
    ]);
    expect(find.text('110 '), findsOneWidget);
    expect(find.text('200 '), findsOneWidget);
    expect(find.text('ME'), findsOneWidget);
  });
}

AuctionBid _bid({
  required int id,
  required int userId,
  required num amount,
  required String nickname,
  required String createdAt,
  bool isActive = true,
}) {
  return AuctionBid(
    id: id,
    productId: 21,
    userId: userId,
    bid: amount,
    isActive: isActive,
    createdAt: createdAt,
    user: User(id: userId, nickname: nickname),
  );
}

Future<void> _show(
  WidgetTester tester,
  String ready,
  List<AuctionBid> bids,
) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'assets/lang',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: ProviderScope(
        overrides: [
          accumulatedBidsProvider.overrideWith(
            (ref) => AccumulatedBidsNotifier(),
          ),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: AuctionBidsHistoryWidget(
                  initialBids: bids,
                  productId: 21,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text(ready).evaluate().isNotEmpty) return;
  }
  final visible = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .join('|');
  fail('history row "$ready" did not appear. Visible text: $visible');
}
