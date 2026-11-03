import 'live_activity_policy.dart';

/// iOS Live Activity surface. Implementations must not create an activity
/// from [endAll].
abstract class IosLiveActivityGateway {
  Future<void> endAll();

  Future<void> upsert({
    required String activityId,
    required Map<String, Object> payload,
    required Duration staleIn,
  });

  Future<void> end(String activityId);
}

/// Android ongoing notification with the same public fields.
abstract class AndroidOngoingGateway {
  Future<void> cancel();

  Future<void> show(Map<String, Object> payload);
}

class LiveRoomActivitySignal {
  const LiveRoomActivitySignal({
    required this.following,
    required this.lotEnded,
    required this.bidInProgress,
    required this.endsAt,
    required this.lotNumber,
    required this.auctionId,
    required this.productId,
    required this.publicPrice,
  });

  final bool following;
  final bool lotEnded;
  final bool bidInProgress;
  final DateTime? endsAt;
  final int? lotNumber;
  final int auctionId;
  final int? productId;
  final num? publicPrice;

  String get activityId =>
      liveActivityId(auctionId: auctionId, productId: productId);

  String get statusLabel =>
      liveActivityStatusLabel(bidInProgress: bidInProgress);
}
