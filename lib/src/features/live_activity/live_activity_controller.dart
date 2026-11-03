import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'android_ongoing_gateway.dart';
import 'ios_live_activity_gateway.dart';
import 'live_activity_gateway.dart';
import 'live_activity_policy.dart';

/// Starts, updates, and ends Dynamic Island / Live Activities and the Android
/// ongoing notification. [clearLeftovers] only ends what a previous process
/// left behind. It never creates an activity.
class LiveActivityController {
  LiveActivityController({
    required IosLiveActivityGateway ios,
    required AndroidOngoingGateway android,
    DateTime Function()? clock,
  }) : _ios = ios,
       _android = android,
       _clock = clock ?? DateTime.now;

  final IosLiveActivityGateway _ios;
  final AndroidOngoingGateway _android;
  final DateTime Function() _clock;

  String? _activityId;
  bool _createdThisProcess = false;
  bool _cleared = false;
  Future<void> _queue = Future<void>.value();

  Future<void> _serialized(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.then((_) {}, onError: (_, _) {});
    return next;
  }

  /// Launch cleanup. Not a start.
  Future<void> clearLeftovers() {
    return _serialized(() async {
      if (_cleared) return;
      _cleared = true;
      if (_createdThisProcess) return;
      await _ios.endAll();
      await _android.cancel();
      _activityId = null;
    });
  }

  Future<void> stopFollowing() {
    return _serialized(_endCurrent);
  }

  Future<void> apply(LiveRoomActivitySignal signal) {
    return _serialized(() async {
      final command = planLiveActivity(
        following: signal.following,
        lotEnded: signal.lotEnded,
        bidInProgress: signal.bidInProgress,
        endsAt: signal.endsAt,
        now: _clock(),
        hasActivity: _activityId != null,
        currentActivityId: _activityId,
        nextActivityId: signal.activityId,
      );
      switch (command) {
        case LiveActivityCommand.none:
          return;
        case LiveActivityCommand.end:
          await _endCurrent();
          return;
        case LiveActivityCommand.upsert:
          await _upsert(signal);
          return;
        case LiveActivityCommand.replace:
          await _endCurrent();
          await _upsert(signal);
          return;
      }
    });
  }

  Future<void> _upsert(LiveRoomActivitySignal signal) async {
    final endsAt = signal.endsAt;
    if (endsAt == null) return;
    final payload = liveActivityPayload(
      lotNumber: signal.lotNumber,
      statusLabel: signal.statusLabel,
      publicPrice: signal.publicPrice,
      endsAt: endsAt,
    );
    final staleIn = staleInFor(endsAt: endsAt, now: _clock());
    await _ios.upsert(
      activityId: signal.activityId,
      payload: payload,
      staleIn: staleIn,
    );
    await _android.show(payload);
    _activityId = signal.activityId;
    _createdThisProcess = true;
  }

  Future<void> _endCurrent() async {
    final id = _activityId;
    _activityId = null;
    if (id != null) {
      await _ios.end(id);
    }
    await _android.cancel();
  }
}

final liveActivityControllerProvider = Provider<LiveActivityController>((ref) {
  return LiveActivityController(
    ios: PluginIosLiveActivityGateway(),
    android: PluginAndroidOngoingGateway(),
  );
});
