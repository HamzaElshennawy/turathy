import 'package:flutter_test/flutter_test.dart';
import 'package:turathy/src/features/live_activity/live_activity_controller.dart';
import 'package:turathy/src/features/live_activity/live_activity_gateway.dart';
import 'package:turathy/src/features/live_activity/live_activity_policy.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 12);

  LiveRoomActivitySignal signal({
    bool following = true,
    bool lotEnded = false,
    bool bidInProgress = false,
    DateTime? endsAt,
    int? lotNumber = 12,
    int? productId = 7,
    num? publicPrice = 25,
    int auctionId = 3,
  }) {
    return LiveRoomActivitySignal(
      following: following,
      lotEnded: lotEnded,
      bidInProgress: bidInProgress,
      endsAt: endsAt,
      lotNumber: lotNumber,
      auctionId: auctionId,
      productId: productId,
      publicPrice: publicPrice,
    );
  }

  group('planLiveActivity', () {
    test('idle when more than 3 minutes remain and no bid', () {
      final command = planLiveActivity(
        following: true,
        lotEnded: false,
        bidInProgress: false,
        endsAt: now.add(const Duration(minutes: 4)),
        now: now,
        hasActivity: false,
        currentActivityId: null,
        nextActivityId: 'turathy-3-7',
      );
      expect(command, LiveActivityCommand.none);
    });

    test('starts inside the 3 minute lead', () {
      final command = planLiveActivity(
        following: true,
        lotEnded: false,
        bidInProgress: false,
        endsAt: now.add(const Duration(minutes: 2)),
        now: now,
        hasActivity: false,
        currentActivityId: null,
        nextActivityId: 'turathy-3-7',
      );
      expect(command, LiveActivityCommand.upsert);
    });

    test(
      'starts on a live bid even when the lot is not in the lead window',
      () {
        final command = planLiveActivity(
          following: true,
          lotEnded: false,
          bidInProgress: true,
          endsAt: now.add(const Duration(minutes: 10)),
          now: now,
          hasActivity: false,
          currentActivityId: null,
          nextActivityId: 'turathy-3-7',
        );
        expect(command, LiveActivityCommand.upsert);
      },
    );

    test('does not start while idle or not following', () {
      final command = planLiveActivity(
        following: false,
        lotEnded: false,
        bidInProgress: true,
        endsAt: now.add(const Duration(minutes: 1)),
        now: now,
        hasActivity: false,
        currentActivityId: null,
        nextActivityId: 'turathy-3-7',
      );
      expect(command, LiveActivityCommand.none);
    });

    test('ends when the lot ends or the timer has passed', () {
      expect(
        planLiveActivity(
          following: true,
          lotEnded: true,
          bidInProgress: true,
          endsAt: now.add(const Duration(minutes: 1)),
          now: now,
          hasActivity: true,
          currentActivityId: 'turathy-3-7',
          nextActivityId: 'turathy-3-7',
        ),
        LiveActivityCommand.end,
      );
      expect(
        planLiveActivity(
          following: true,
          lotEnded: false,
          bidInProgress: false,
          endsAt: now.subtract(const Duration(seconds: 1)),
          now: now,
          hasActivity: true,
          currentActivityId: 'turathy-3-7',
          nextActivityId: 'turathy-3-7',
        ),
        LiveActivityCommand.end,
      );
    });

    test('ending with no activity does not create one', () {
      expect(
        planLiveActivity(
          following: false,
          lotEnded: true,
          bidInProgress: false,
          endsAt: null,
          now: now,
          hasActivity: false,
          currentActivityId: null,
          nextActivityId: 'turathy-3-7',
        ),
        LiveActivityCommand.none,
      );
    });

    test('keeps an activity after the lead window if it already started', () {
      expect(
        planLiveActivity(
          following: true,
          lotEnded: false,
          bidInProgress: false,
          endsAt: now.add(const Duration(minutes: 10)),
          now: now,
          hasActivity: true,
          currentActivityId: 'turathy-3-7',
          nextActivityId: 'turathy-3-7',
        ),
        LiveActivityCommand.upsert,
      );
    });

    test('lot change ends when the next lot does not qualify', () {
      expect(
        planLiveActivity(
          following: true,
          lotEnded: false,
          bidInProgress: false,
          endsAt: now.add(const Duration(minutes: 10)),
          now: now,
          hasActivity: true,
          currentActivityId: 'turathy-3-7',
          nextActivityId: 'turathy-3-8',
        ),
        LiveActivityCommand.end,
      );
    });
  });

  group('payload', () {
    test(
      'keeps the public price and drops reserve, estimate, and identity',
      () {
        final payload = sanitizeLiveActivityPayload({
          'lotNumber': '12',
          'statusLabel': 'Bidding',
          'bidPrice': '25',
          'endsAt': 1,
          'minBidPrice': 400,
          'actualPrice': 900,
          'userName': 'secret',
          'phone': '0500000000',
        });
        expect(payload.keys.toSet(), kLiveActivityPayloadKeys);
        expect(payload.containsKey('minBidPrice'), isFalse);
        expect(payload.containsKey('actualPrice'), isFalse);
        expect(payload['bidPrice'], '25');
      },
    );

    test('builder omits a missing public price', () {
      final payload = liveActivityPayload(
        lotNumber: 4,
        statusLabel: 'Ending',
        publicPrice: null,
        endsAt: now,
      );
      expect(payload.containsKey('bidPrice'), isFalse);
      expect(payload.containsKey('minBidPrice'), isFalse);
      expect(payload['lotNumber'], '4');
    });
  });

  test('stale window stays between one minute and eight hours', () {
    expect(
      staleInFor(endsAt: now.add(const Duration(seconds: 10)), now: now),
      kDynamicIslandMinStale,
    );
    expect(
      staleInFor(endsAt: now.add(const Duration(hours: 20)), now: now),
      kDynamicIslandMaxAge,
    );
  });

  test('launch clear ends leftovers and does not create an activity', () async {
    final ios = _FakeIos();
    final android = _FakeAndroid();
    final controller = LiveActivityController(
      ios: ios,
      android: android,
      clock: () => now,
    );

    await controller.clearLeftovers();

    expect(ios.endAllCount, 1);
    expect(android.cancelCount, 1);
    expect(ios.upserts, isEmpty);
    expect(android.shown, isEmpty);
  });

  test('a live bid starts both surfaces and leaving ends both', () async {
    final ios = _FakeIos();
    final android = _FakeAndroid();
    final controller = LiveActivityController(
      ios: ios,
      android: android,
      clock: () => now,
    );

    await controller.apply(
      signal(endsAt: now.add(const Duration(minutes: 10)), bidInProgress: true),
    );
    expect(ios.upserts, hasLength(1));
    expect(android.shown, hasLength(1));
    expect(ios.upserts.single.payload.containsKey('minBidPrice'), isFalse);
    expect(ios.upserts.single.staleIn <= kDynamicIslandMaxAge, isTrue);

    await controller.stopFollowing();
    expect(ios.ended, ['turathy-3-7']);
    expect(android.cancelCount, 1);
  });

  test('lot end clears an activity that was already showing', () async {
    final ios = _FakeIos();
    final android = _FakeAndroid();
    final controller = LiveActivityController(
      ios: ios,
      android: android,
      clock: () => now,
    );

    await controller.apply(signal(endsAt: now.add(const Duration(minutes: 2))));
    await controller.apply(
      signal(endsAt: now.add(const Duration(minutes: 2)), lotEnded: true),
    );

    expect(ios.ended, ['turathy-3-7']);
    expect(android.cancelCount, 1);
    expect(android.shown, hasLength(1));
  });

  test(
    'clear after a start in this process does not end the new activity',
    () async {
      final ios = _FakeIos();
      final android = _FakeAndroid();
      final controller = LiveActivityController(
        ios: ios,
        android: android,
        clock: () => now,
      );

      await controller.apply(
        signal(endsAt: now.add(const Duration(minutes: 2))),
      );
      await controller.clearLeftovers();

      expect(ios.endAllCount, 0);
      expect(ios.ended, isEmpty);
      expect(android.cancelCount, 0);
    },
  );
}

class _Upsert {
  _Upsert(this.activityId, this.payload, this.staleIn);

  final String activityId;
  final Map<String, Object> payload;
  final Duration staleIn;
}

class _FakeIos implements IosLiveActivityGateway {
  int endAllCount = 0;
  final List<_Upsert> upserts = [];
  final List<String> ended = [];

  @override
  Future<void> endAll() async {
    endAllCount += 1;
  }

  @override
  Future<void> upsert({
    required String activityId,
    required Map<String, Object> payload,
    required Duration staleIn,
  }) async {
    upserts.add(_Upsert(activityId, payload, staleIn));
  }

  @override
  Future<void> end(String activityId) async {
    ended.add(activityId);
  }
}

class _FakeAndroid implements AndroidOngoingGateway {
  int cancelCount = 0;
  final List<Map<String, Object>> shown = [];

  @override
  Future<void> cancel() async {
    cancelCount += 1;
  }

  @override
  Future<void> show(Map<String, Object> payload) async {
    shown.add(payload);
  }
}
