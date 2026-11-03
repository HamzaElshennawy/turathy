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
  PluginIosLiveActivityGateway({LiveActivities? plugin}) : _plugin = plugin;

  LiveActivities? _plugin;
  bool _ready = false;

  /// The TestFlight profile has no App Group. live_activities 2.4.3 force-unwraps
  /// `UserDefaults(suiteName:)`, which is nil without that entitlement and kills
  /// the process. Stay off until the profile includes the group.
  static const bool enabled = false;

  Future<LiveActivities?> _ensureReady() async {
    if (!enabled || kIsWeb || !Platform.isIOS) return null;
    final plugin = _plugin ??= LiveActivities();
    if (_ready) return plugin;
    await plugin.init(
      appGroupId: kTurathyAppGroupId,
      requireNotificationPermission: false,
    );
    _ready = true;
    return plugin;
  }

  @override
  Future<void> endAll() async {
    final plugin = await _ensureReady();
    if (plugin == null) return;
    await plugin.endAllActivities();
  }

  @override
  Future<void> upsert({
    required String activityId,
    required Map<String, Object> payload,
    required Duration staleIn,
  }) async {
    final plugin = await _ensureReady();
    if (plugin == null) return;
    final supported = await plugin.areActivitiesSupported();
    if (supported != true) return;
    final activitiesEnabled = await plugin.areActivitiesEnabled();
    if (activitiesEnabled != true) return;
    await plugin.createOrUpdateActivity(
      activityId,
      payload,
      removeWhenAppIsKilled: false,
      staleIn: staleIn,
    );
  }

  @override
  Future<void> end(String activityId) async {
    final plugin = await _ensureReady();
    if (plugin == null) return;
    await plugin.endActivity(activityId);
  }
}
