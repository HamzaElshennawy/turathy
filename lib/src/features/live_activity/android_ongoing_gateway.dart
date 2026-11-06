import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'live_activity_gateway.dart';
import 'live_activity_policy.dart';

/// Title and body for the ongoing auction notification.
/// Status words stay the shared English payload; this surface is Arabic.
class AndroidLiveNotice {
  const AndroidLiveNotice({required this.title, required this.body});

  final String title;
  final String body;
}

AndroidLiveNotice androidLiveNotice({
  required String lotNumber,
  required String status,
  required String? price,
}) {
  final title = lotNumber.isEmpty ? 'مزاد مباشر' : 'بند $lotNumber';
  final statusAr = switch (status) {
    'Bidding' => 'جاري المزايدة',
    'Ending' => 'ينتهي قريباً',
    '' => 'مباشر',
    _ => status,
  };
  final body = (price == null || price.isEmpty)
      ? statusAr
      : '$statusAr · $price ر.س';
  return AndroidLiveNotice(title: title, body: body);
}

/// Ongoing status notification for the same lot fields as Dynamic Island.
///
/// Android 14 and later can still dismiss an `ongoing` notification that is
/// not owned by a foreground service. flutter_local_notifications 18 does not
/// require a foreground service for this channel, so none is started.
class PluginAndroidOngoingGateway implements AndroidOngoingGateway {
  PluginAndroidOngoingGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  bool _permissionAsked = false;

  Future<void> _ensureReady() async {
    if (_ready || kIsWeb || !Platform.isAndroid) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            kAndroidLiveActivityChannelId,
            'المزاد المباشر',
            description: 'عدّاد البند أثناء المزاد',
            importance: Importance.low,
          ),
        );
    _ready = true;
  }

  Future<bool> _ensurePermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (_permissionAsked) return false;
    _permissionAsked = true;
    final next = await Permission.notification.request();
    return next.isGranted;
  }

  @override
  Future<void> cancel() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _ensureReady();
    await _plugin.cancel(kAndroidLiveActivityNotificationId);
  }

  @override
  Future<void> show(Map<String, Object> payload) async {
    if (kIsWeb || !Platform.isAndroid) return;
    await _ensureReady();
    if (!await _ensurePermission()) return;
    final endsAtMs = payload['endsAt'];
    if (endsAtMs is! int) return;
    final notice = androidLiveNotice(
      lotNumber: payload['lotNumber'] as String? ?? '',
      status: payload['statusLabel'] as String? ?? '',
      price: payload['bidPrice'] as String?,
    );
    await _plugin.show(
      kAndroidLiveActivityNotificationId,
      notice.title,
      notice.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kAndroidLiveActivityChannelId,
          'المزاد المباشر',
          channelDescription: 'عدّاد البند أثناء المزاد',
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
          showWhen: true,
          when: endsAtMs,
          usesChronometer: true,
          chronometerCountDown: true,
          onlyAlertOnce: true,
          category: AndroidNotificationCategory.status,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
