/// {@category Core}
///
/// Integrated Firebase Cloud Messaging (FCM) and Local Notifications service.
/// 
/// This file handles:
/// - Requesting OS-level notification permissions.
/// - FCM token retrieval and backend registration/unregistration.
/// - Local Notification channel setup (especially for Android).
/// - Routing logic for interactive notifications (deep-linking).
/// - Handling messages in foreground, background, and terminated states.
library;

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/notifications/data/notifications_repository.dart';
import '../cache/cached_variables.dart';
import '../analytics/analytics_service.dart';
import 'package:turathy/src/routing/app_router.dart';
import 'package:turathy/src/routing/rout_constants.dart';
import 'dart:convert';

/// High-level background message interceptor.
/// 
/// **Warning:** This must be a top-level function or a static method annotated 
/// with `@pragma('vm:entry-point')` to be reachable while the app is in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log(
    'Handling background message: ${message.messageId}',
    time: DateTime.now(),
    level: 1,
  );
}

/// The central coordinator for the app's notification subsystem.
/// 
/// Implemented as a Singleton to ensure consistent stream management and 
/// listener registration across the app lifecycle.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// The most recently retrieved FCM registration token.
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  String? _apnsToken;
  String? get apnsToken => _apnsToken;

  /// Internal broadcast controller for exposing incoming foreground messages.
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();

  /// A stream of [RemoteMessage] instances received while the app is in the foreground.
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  /// Boots up the notification system.
  /// 
  /// Usually called in `main.dart` after Firebase initialization.
  /// Sets up permissions, local channels, token listeners, and message handlers.
  Future<void> initialize() async {
    // 1. Seek OS permission (iOS) or prompt (Android 13+)
    await _requestPermission();

    // 2. Prepare local notification library (used for foreground visibility)
    await _initLocalNotifications();

    // 3. Retrieve and sync the push token
    await _getToken();

    // 4. Attach persistent listeners
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 5. Handle "Cold Start" case where user clicked a notification to open the app
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Internal: Triggers the native permission dialog.
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log(
      'FCM Permission status: ${settings.authorizationStatus}',
      time: DateTime.now(),
      level: 1,
    );

    // Ensure notifications appear even when the app is active
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Internal: Configures the [FlutterLocalNotificationsPlugin] for cross-platform display.
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Define a High Importance channel for Android to support Heads-up notifications
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'turathy_notifications',
        'turathy Notifications',
        description: 'Notifications from turathy app',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Internal: Fetches the FCM token with specialized retry logic for iOS APNs readiness.
  Future<void> _getToken() async {
    try {
      if (Platform.isIOS) {
        // iOS requires a valid APNs token before Firebase can generate an FCM token.
        // We retry for up to 10 seconds to account for network/handshake delay.
        int retries = 0;
        while (retries < 5) {
          _apnsToken = await _messaging.getAPNSToken();
          if (_apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 2));
          retries++;
        }
        if (_apnsToken == null) {
          log('APNs token not set. Token generation skipped.');
          return;
        }
      }

      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e, stack) {
      log('Error getting FCM token: $e', stackTrace: stack);
    }
  }

  /// Internal: Callback for token rotation events.
  Future<void> _handleTokenRefresh(String newToken) async {
    log('FCM Token refreshed: $newToken');
    _fcmToken = newToken;
    await _registerTokenWithBackend(newToken);
  }

  /// Internal: Syncs the [token] to the Turathy backend for the current user.
  Future<void> _registerTokenWithBackend(String token) async {
    final userId = CachedVariables.userId;
    if (userId == null) {
      log('User not logged in; registration deferred.');
      return;
    }

    try {
      final platformToSend = Platform.isAndroid ? 'ANDROID' : 'IOS';
      await NotificationsRepository.registerDevice(
        userId: userId,
        token: token,
        platform: platformToSend,
        apnsToken: Platform.isIOS ? _apnsToken : null,
      );
      log('FCM token registered with backend successfully');
    } catch (e, stack) {
      log('Error registering FCM token: $e', stackTrace: stack);
    }
  }

  /// Cleans up the device token from the backend database (usually called on Logout).
  Future<void> unregisterDevice() async {
    if (_fcmToken == null) return;

    try {
      await NotificationsRepository.unregisterDevice(_fcmToken!);
      log('FCM token unregistered from backend');
    } catch (e) {
      log('Error unregistering FCM token: $e');
    }
  }

  /// Main handler for foreground messages.
  /// 
  /// Broadcasts the [message] to UI listeners via [_messageController] and 
  /// triggers a local 'Heads-up' notification for immediate visibility.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log('Received foreground message: ${message.messageId}');
    
    _messageController.add(message);

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'turathy_notifications',
          'turathy Notifications',
          channelDescription: 'Notifications from turathy app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  /// Callback for when a Firebase notification is tapped while the app is 
  /// in background or terminated state.
  void _handleMessageOpenedApp(RemoteMessage message) {
    log('Message opened app: ' + (message.messageId ?? 'unknown')); 
    _logNotificationOpened(message.data);
    _navigateBasedOnData(message.data);
  }

  /// Callback for when a Local notification is tapped.
  /// 
  /// Since [RemoteMessage.data] becomes a stringified [Map] when passed as a 
  /// payload, this method includes defensive parsing logic to recover the 
  /// JSON structure before routing.
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.payload!) as Map<String, dynamic>;
      } catch (e) {
        // Fallback: Manually parse the "{Key: Value, ...}" stringified map 
        // if standard JSON decoding fails (legacy payloads).
        try {
          String content = response.payload!
              .replaceAll('{', '')
              .replaceAll('}', '')
              .trim();
          if (content.isNotEmpty) {
            List<String> pairs = content.split(',');
            for (String pair in pairs) {
              List<String> keyValue = pair.split(':');
              if (keyValue.length >= 2) {
                data[keyValue[0].trim()] = keyValue.sublist(1).join(':').trim();
              }
            }
          }
        } catch (_) {}
      }

      if (data.isNotEmpty) {
        _logNotificationOpened(data);
        _navigateBasedOnData(data);
      }
    }
  }


  void _logNotificationOpened(Map<String, dynamic> data) {
    AnalyticsService.logNotificationOpened(
      type: data['type']?.toString(),
      auctionId: (data['auction_id'] ?? data['auctionId'])?.toString(),
      productId: data['product_id']?.toString(),
      orderId: (data['order_id'] ?? data['orderId'])?.toString(),
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      log('Failed to open notification URL: $error', stackTrace: stackTrace);
    }
  }
  /// The routing engine for push notifications.
  /// 
  /// Inspects the `type` and ID keys (`auction_id`, `product_id`, `order_id`) 
  /// to perform deep-linking via [goRouter].
  /// 
  /// Standard Types mapped:
  /// - `AUCTION_STARTED`, `AUCTION_WON`, `AUCTION_ENDING_SOON`: Redirects to Live Auction.
  /// - `OUTBID`, `NEW_BID`: Redirects to Auction Details.
  /// - `ORDER_STATUS`, `PAYMENT_APPROVED`: Redirects to Order Details.
  void _navigateBasedOnData(Map<String, dynamic> data) {
    log('Navigating based on data: $data');

    final type = data['type']?.toString();
    final externalUrl = data['url']?.toString();

    if ((type == 'PROMOTIONAL' || type == 'BROADCAST') &&
        externalUrl != null &&
        externalUrl.isNotEmpty) {
      _openExternalUrl(externalUrl);
      return;
    }

    // Auction Group Logic
    if (type == 'AUCTION_STARTED' ||
        type == 'AUCTION_WON' ||
        type == 'AUCTION_ENDING_SOON') {
      final auctionId = data['auction_id'] ?? data['id'] ?? data['auctionId'];
      if (auctionId != null) {
        goRouter.pushNamed(
          RouteConstants.liveAuction,
          pathParameters: {'id': auctionId.toString()},
        );
        return;
      }
    } else if (type == 'OUTBID' || type == 'NEW_BID') {
      final auctionId = data['auction_id'] ?? data['id'] ?? data['auctionId'];
      if (auctionId != null) {
        goRouter.pushNamed(
          RouteConstants.auctionDetails,
          pathParameters: {'id': auctionId.toString()},
        );
        return;
      }
    } 
    // Order Group Logic
    else if (type == 'ORDER_STATUS' || type == 'PAYMENT_APPROVED') {
      final orderId = data['order_id'] ?? data['orderId'];
      if (orderId != null) {
        goRouter.pushNamed(
          RouteConstants.orderDetails,
          pathParameters: {'id': orderId.toString()},
        );
      } else {
        goRouter.pushNamed(RouteConstants.orders);
      }
      return;
    }

    // Generic fallback routing based on presence of IDs
    if (data.containsKey('auction_id') || data['type'] == 'AUCTION') {
      final auctionId = data['auction_id'] ?? data['auctionId'];
      if (auctionId != null) {
        goRouter.pushNamed(
          RouteConstants.liveAuction,
          pathParameters: {'id': auctionId.toString()},
        );
      }
    } else if (data.containsKey('product_id') || data['type'] == 'PRODUCT') {
      final productId = data['product_id'];
      if (productId != null) {
        goRouter.pushNamed(
          RouteConstants.productDetails,
          pathParameters: {'id': productId.toString()},
        );
      }
    } else if (data.containsKey('order_id') || data.containsKey('orderId')) {
      final orderId = data['order_id'] ?? data['orderId'];
      if (orderId != null) {
        goRouter.pushNamed(
          RouteConstants.orderDetails,
          pathParameters: {'id': orderId.toString()},
        );
      }
    }
  }

  /// Forces a token synchronization with the backend.
  /// 
  /// Typically called after a successful login event to ensure the user's
  /// active account is linked to the current device's push token.
  Future<void> registerAfterLogin() async {
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    } else {
      await _getToken();
    }
  }

  /// Triggers a local OS notification manually.
  /// 
  /// * [title]: The primary heading of the notification.
  /// * [body]: The detailed text content.
  /// * [payload]: A JSON-stringified map to be parsed on tap.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'turathy_notifications',
      'turathy Notifications',
      channelDescription: 'Notifications from turathy app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload ?? '{"type": "local"}',
    );
  }

  /// Displays a hardcoded test notification for development and troubleshooting.
  Future<void> showTestNotification() async {
    await showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from the app',
      payload: '{"type": "test"}',
    );
  }
}

/// Singleton instance available across the app.
final fcmService = FCMService();








