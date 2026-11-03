// Dynamic Island / Live Activities start rules.
//
// A live activity exists only while the user is inside the live room and the
// current lot is about to end, or a bid is in progress. Opening the app does
// not start one. Reserve (minBidPrice) and estimate (actualPrice) never enter
// the payload.

const Duration kDynamicIslandLead = Duration(minutes: 3);
const Duration kDynamicIslandStaleGrace = Duration(seconds: 30);
const Duration kDynamicIslandMaxAge = Duration(hours: 8);
const Duration kDynamicIslandMinStale = Duration(minutes: 1);

const String kTurathyAppGroupId = 'group.com.deepblue.turathy';
const int kAndroidLiveActivityNotificationId = 91011;
const String kAndroidLiveActivityChannelId = 'turathy_live_activity';

const Set<String> kLiveActivityPayloadKeys = {
  'lotNumber',
  'statusLabel',
  'bidPrice',
  'endsAt',
};

enum LiveActivityCommand { none, end, upsert, replace }

String liveActivityStatusLabel({required bool bidInProgress}) {
  return bidInProgress ? 'Bidding' : 'Ending';
}

String liveActivityId({required int auctionId, required int? productId}) {
  return 'turathy-$auctionId-${productId ?? 0}';
}

/// How long ActivityKit should keep the activity before marking it stale.
/// The plugin ignores a [Duration] shorter than one minute, so the floor is
/// one minute. Apple's activity window is about eight hours.
Duration staleInFor({required DateTime endsAt, required DateTime now}) {
  final until = endsAt.add(kDynamicIslandStaleGrace).difference(now);
  if (until >= kDynamicIslandMaxAge) return kDynamicIslandMaxAge;
  if (until < kDynamicIslandMinStale) return kDynamicIslandMinStale;
  return until;
}

LiveActivityCommand planLiveActivity({
  required bool following,
  required bool lotEnded,
  required bool bidInProgress,
  required DateTime? endsAt,
  required DateTime now,
  required bool hasActivity,
  required String? currentActivityId,
  required String nextActivityId,
}) {
  final expired = endsAt == null || !endsAt.isAfter(now);
  if (!following || lotEnded || expired) {
    return hasActivity ? LiveActivityCommand.end : LiveActivityCommand.none;
  }
  final remaining = endsAt.difference(now);
  final qualifies = bidInProgress || remaining <= kDynamicIslandLead;
  final switched = hasActivity && currentActivityId != nextActivityId;
  if (switched) {
    return qualifies ? LiveActivityCommand.replace : LiveActivityCommand.end;
  }
  if (hasActivity || qualifies) return LiveActivityCommand.upsert;
  return LiveActivityCommand.none;
}

/// Copies only the public fields. Any other key, including reserve and
/// estimate, is dropped.
Map<String, Object> sanitizeLiveActivityPayload(Map<String, Object?> raw) {
  final payload = <String, Object>{};
  for (final key in kLiveActivityPayloadKeys) {
    final value = raw[key];
    if (value != null) payload[key] = value;
  }
  return payload;
}

String formatPublicBidPrice(num value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toString();
}

Map<String, Object> liveActivityPayload({
  required int? lotNumber,
  required String statusLabel,
  required num? publicPrice,
  required DateTime endsAt,
}) {
  final raw = <String, Object?>{
    'lotNumber': (lotNumber == null || lotNumber <= 0) ? '' : '$lotNumber',
    'statusLabel': statusLabel,
    'endsAt': endsAt.millisecondsSinceEpoch,
    'bidPrice': (publicPrice != null && publicPrice > 0)
        ? formatPublicBidPrice(publicPrice)
        : null,
    'minBidPrice': null,
    'actualPrice': null,
  };
  return sanitizeLiveActivityPayload(raw);
}
