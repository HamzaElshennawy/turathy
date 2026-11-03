import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

import 'live_activity_gateway.dart';
import 'live_activity_policy.dart';

/// Widget Extension bridge. [init] does not create an activity.
///
/// live_activities 2.4.3 has no switch to disable ActivityKit push tokens.
/// This release never reads those tokens and never uploads them. Updates come
/// from the socket and the on-device countdown.
class PluginIosLiveActivityGateway implements IosLiveActivityGateway {
  PluginIosLiveActivityGateway({LiveActivities? plugin})
    : _plugin = plugin ?? LiveActivities();

  final LiveActivities _plugin;
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready || kIsWeb || !Platform.isIOS) return;
    await _plugin.init(
      appGroupId: kTurathyAppGroupId,
      requireNotificationPermission: false,
    );
    _ready = true;
  }

  @override
  Future<void> endAll() async {
    if (kIsWeb || !Platform.isIOS) return;
    await _ensureReady();
    await _plugin.endAllActivities();
  }

  @override
  Future<void> upsert({
    required String activityId,
    required Map<String, Object> payload,
    required Duration staleIn,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;
    await _ensureReady();
    final supported = await _plugin.areActivitiesSupported();
    if (supported != true) return;
    final enabled = await _plugin.areActivitiesEnabled();
    if (enabled != true) return;
    await _plugin.createOrUpdateActivity(
      activityId,
      payload,
      removeWhenAppIsKilled: false,
      staleIn: staleIn,
    );
  }

  @override
  Future<void> end(String activityId) async {
    if (kIsWeb || !Platform.isIOS) return;
    await _ensureReady();
    await _plugin.endActivity(activityId);
  }
}
