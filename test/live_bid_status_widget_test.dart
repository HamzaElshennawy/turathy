import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/domain/auction_model.dart';
import 'package:turathy/src/features/auctions/domain/max_bid_model.dart';
import 'package:turathy/src/features/auctions/presentation/auction_screen/widgets/auction_bidding_controls_widget.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CachedVariables.userId = 7;
  });

  tearDown(() {
    CachedVariables.userId = null;
  });

  testWidgets('a later newBid flips the leader without changing the lot', (
    tester,
  ) async {
    await EasyLocalization.ensureInitialized();
    final accepted = StreamController<BidAcceptedEvent>.broadcast();
    final placed = StreamController<BidPlacedEvent>.broadcast();
    final rejected = StreamController<BidRejectedEvent>.broadcast();
    final extended = StreamController<TimerExtendedEvent>.broadcast();
    addTearDown(accepted.close);
    addTearDown(placed.close);
    addTearDown(rejected.close);
    addTearDown(extended.close);

    final expiry = DateTime.now().add(const Duration(minutes: 5));
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        path: 'assets/lang',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: ProviderScope(
          overrides: [
            bidAcceptedProvider.overrideWith((ref) => accepted.stream),
            newBidEventProvider.overrideWith((ref) => placed.stream),
            bidRejectedProvider.overrideWith((ref) => rejected.stream),
            timerExtendedEventProvider.overrideWith((ref) => extended.stream),
            auctionProductChangeProvider.overrideWith((ref) => null),
            userMaxBidsProvider.overrideWith((ref) async => <MaxBidModel>[]),
            getUserOrdersProvider.overrideWith(
              (ref, int userId) async => <OrderModel>[],
            ),
          ],
          child: Builder(
            builder: (context) {
              return MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: AuctionBiddingControlsWidget(
                    showOnlyMaxBid: true,
                    auction: AuctionModel(
                      id: 1,
                      isLiveAuction: true,
                      isLive: true,
                      currentProductId: 6,
                      bidPrice: 30,
                      expiryDate: expiry,
                    ),
                    selectedProduct: AuctionProducts(id: 6),
                    expiryDate: expiry,
                    onPlaceBid: (qty, price, productId) {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    accepted.add(
      BidAcceptedEvent(
        productId: 6,
        currentPrice: 40,
        submittedAmount: 40,
        leaderUserId: 7,
        leaderBidId: 10,
        auctionBids: [
          AuctionBid(id: 10, productId: 6, userId: 7, bid: 40, isActive: true),
        ],
      ),
    );
    await _pumpFrames(tester);

    expect(_price(40), findsOneWidget);
    expect(find.text('المواجهة رقم: 001'), findsOneWidget);
    expect(find.text('أعلى مزايدة'), findsOneWidget);
    expect(find.text('لديك مزايدة تلقائية بحد أقصى 40 ر.س'), findsOneWidget);

    placed.add(
      BidPlacedEvent(
        productId: 6,
        currentPrice: 40,
        newBid: AuctionBid(
          id: 11,
          productId: 6,
          userId: 80,
          bid: 40,
          isActive: true,
        ),
        auctionBids: [
          AuctionBid(id: 11, productId: 6, userId: 80, bid: 40),
          AuctionBid(id: 10, productId: 6, userId: 7, bid: 40),
        ],
      ),
    );
    await _pumpFrames(tester);
    expect(_price(40), findsOneWidget);
    expect(find.text('هناك مزايدة أعلى منك'), findsOneWidget);
    expect(find.text('أعلى مزايدة'), findsNothing);
    expect(find.text('لديك مزايدة تلقائية بحد أقصى 40 ر.س'), findsNothing);

    placed.add(
      BidPlacedEvent(
        productId: 6,
        currentPrice: 50,
        newBid: AuctionBid(
          id: 12,
          productId: 6,
          userId: 80,
          bid: 50,
          isActive: true,
        ),
        auctionBids: [
          AuctionBid(id: 12, productId: 6, userId: 80, bid: 50),
          AuctionBid(id: 10, productId: 6, userId: 7, bid: 40),
        ],
      ),
    );
    await _pumpFrames(tester);

    expect(_price(50), findsOneWidget);
    expect(find.text('المواجهة رقم: 002'), findsOneWidget);
    expect(find.text('هناك مزايدة أعلى منك'), findsOneWidget);
    expect(find.text('أعلى مزايدة'), findsNothing);
    expect(find.text('لديك مزايدة تلقائية بحد أقصى 40 ر.س'), findsNothing);

    accepted.add(
      const BidAcceptedEvent(
        productId: 6,
        currentPrice: 40,
        submittedAmount: 40,
        leaderUserId: 7,
        leaderBidId: 10,
      ),
    );
    await _pumpFrames(tester);

    expect(_price(50), findsOneWidget);
    expect(find.text('المواجهة رقم: 002'), findsOneWidget);
    expect(find.text('هناك مزايدة أعلى منك'), findsOneWidget);
    expect(find.text('أعلى مزايدة'), findsNothing);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        path: 'assets/lang',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: ProviderScope(
          overrides: [
            bidAcceptedProvider.overrideWith((ref) => accepted.stream),
            newBidEventProvider.overrideWith((ref) => placed.stream),
            bidRejectedProvider.overrideWith((ref) => rejected.stream),
            timerExtendedEventProvider.overrideWith((ref) => extended.stream),
            auctionProductChangeProvider.overrideWith((ref) => null),
            userMaxBidsProvider.overrideWith((ref) async => <MaxBidModel>[]),
            getUserOrdersProvider.overrideWith(
              (ref, int userId) async => <OrderModel>[],
            ),
          ],
          child: Builder(
            builder: (context) {
              return MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: AuctionBiddingControlsWidget(
                    showOnlyMaxBid: true,
                    auction: AuctionModel(
                      id: 1,
                      isLiveAuction: true,
                      isLive: true,
                      currentProductId: 7,
                      bidPrice: 15,
                      expiryDate: expiry,
                    ),
                    selectedProduct: AuctionProducts(id: 7),
                    expiryDate: expiry,
                    onPlaceBid: (qty, price, productId) {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await _pumpFrames(tester);
    expect(_price(15), findsOneWidget);
    accepted.add(
      const BidAcceptedEvent(
        productId: 6,
        currentPrice: 40,
        submittedAmount: 80,
        leaderUserId: 7,
        leaderBidId: 13,
      ),
    );
    placed.add(
      BidPlacedEvent(
        productId: 6,
        currentPrice: 90,
        newBid: AuctionBid(id: 14, productId: 6, userId: 80, bid: 90),
      ),
    );
    await _pumpFrames(tester);
    expect(_price(15), findsOneWidget);
    expect(_price(90), findsNothing);
    expect(find.text('أعلى مزايدة'), findsNothing);
    expect(find.text('هناك مزايدة أعلى منك'), findsNothing);
  });
}

Finder _price(int amount) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data == '$amount' &&
        widget.style?.fontSize == 28,
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
