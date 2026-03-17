import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../features/notifications/data/notifications_repository.dart';
import '../cache/cached_variables.dart';
import 'package:turathy/src/routing/app_router.dart';
import 'package:turathy/src/routing/rout_constants.dart';
import 'dart:convert';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
  log(
    'Handling background message: ${message.messageId}',
    time: DateTime.now(),
    level: 1,
  );
}

/// FCM Service for handling push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Stream controller for broadcasting foreground messages
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of foreground messages
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  /// Initialize FCM service
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initLocalNotifications();

    // Get FCM token
    await _getToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Request notification permissions
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

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initialize local notifications for foreground display
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

    // Create notification channel for Android
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

  /// Get FCM token and register with backend
  Future<void> _getToken() async {
    try {
      if (Platform.isIOS) {
        // Wait for APNs token before trying to get FCM token to avoid 'apns-token-not-set' error
        int retries = 0;
        String? apnsToken;
        while (retries < 5) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) {
            log(
              'APNs Token successfully retrieved.',
              time: DateTime.now(),
              level: 1,
            );
            break;
          }
          log('APNs Token is null, waiting...', time: DateTime.now(), level: 1);
          await Future.delayed(const Duration(seconds: 2));
          retries++;
        }
        if (apnsToken == null) {
          log(
            'APNs token not set after retries. Skipping FCM token generation (common on simulators without APNs capabilities).',
            time: DateTime.now(),
            level: 1,
          );
          return;
        }
      }

      _fcmToken = await _messaging.getToken();
      log('FCM Token: $_fcmToken', time: DateTime.now(), level: 1);

      if (_fcmToken != null) {
        log(
          'FCM Token retrieved successfully: $_fcmToken',
          time: DateTime.now(),
          level: 1,
        );
        await _registerTokenWithBackend(_fcmToken!);
      } else {
        log(
          'FCM Token is null after getToken()',
          time: DateTime.now(),
          level: 1,
        );
      }
    } catch (e, stack) {
      log(
        'Error getting FCM token: $e',
        time: DateTime.now(),
        level: 1,
        stackTrace: stack,
      );
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    log('FCM Token refreshed: $newToken', time: DateTime.now(), level: 1);
    _fcmToken = newToken;
    await _registerTokenWithBackend(newToken);
  }

  /// Register token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    final userId = CachedVariables.userId;
    if (userId == null) {
      log(
        'User not logged in, skipping token registration for now. Token will be registered after login.',
        time: DateTime.now(),
        level: 1,
      );
      return;
    }

    log(
      'Attempting to register FCM token with backend for user $userId...',
      time: DateTime.now(),
      level: 1,
    );

    try {
      final platform = Platform.isAndroid
          ? 'android'
          : 'ios'; // Lowercase might be expected by backend, strict check?
      // Keeping original 'ANDROID'/'IOS' based on existing code, but logging it.
      final platformToSend = Platform.isAndroid ? 'ANDROID' : 'IOS';

      log(
        'Sending registration request: Token=$token, Platform=$platformToSend',
        time: DateTime.now(),
        level: 1,
      );

      await NotificationsRepository.registerDevice(
        userId: userId,
        token: token,
        platform: platformToSend,
      );
      log(
        'FCM token registered with backend successfully',
        time: DateTime.now(),
        level: 1,
      );
    } catch (e, stack) {
      log(
        'Error registering FCM token with backend: $e',
        time: DateTime.now(),
        level: 1,
        stackTrace: stack,
      );
    }
  }

  /// Unregister device token on logout
  Future<void> unregisterDevice() async {
    if (_fcmToken == null) return;

    try {
      await NotificationsRepository.unregisterDevice(_fcmToken!);
      log(
        'FCM token unregistered from backend',
        time: DateTime.now(),
        level: 1,
      );
    } catch (e) {
      log('Error unregistering FCM token: $e', time: DateTime.now(), level: 1);
    }
  }

  /// Handle foreground message - show local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log(
      'Received foreground message: ${message.messageId}',
      time: DateTime.now(),
      level: 1,
    );
    log('Message data: ${message.data}', time: DateTime.now(), level: 1);
    if (message.notification != null) {
      log(
        'Message notification: ${message.notification?.title}, ${message.notification?.body}',
        time: DateTime.now(),
        level: 1,
      );
    }

    // Add message to stream for UI updates
    _messageController.add(message);

    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
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

  /// Handle notification tap when app is in background/terminated
  void _handleMessageOpenedApp(RemoteMessage message) {
    log(
      'Message opened app: ${message.messageId}',
      time: DateTime.now(),
      level: 1,
    );
    _navigateBasedOnData(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    log(
      'Notification tapped: ${response.payload}',
      time: DateTime.now(),
      level: 1,
    );

    if (response.payload != null) {
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.payload!) as Map<String, dynamic>;
      } catch (e) {
        log('Error parsing notification payload initially: $e');
        // Try manual parsing for unquoted key-values
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
                String key = keyValue[0].trim();
                String value = keyValue.sublist(1).join(':').trim();
                data[key] = value;
              }
            }
          }
        } catch (e2) {
          log('Failed to manually parse notification data payload: $e2');
        }
      }

      if (data.isNotEmpty) {
        _navigateBasedOnData(data);
      }
    }
  }

  /// Navigate based on notification data
  void _navigateBasedOnData(Map<String, dynamic> data) {
    // Ensure we are on the main thread and context is available if needed,
    // but GoRouter works without context if using the global instance.
    log('Navigating based on data: $data');

    // Check for specific types or keys
    // Adjust keys (auction_id, product_id, order_id) based on actual backend payload

    // First let's check exact Notification Screen logic
    final type = data['type']?.toString();

    if (type == 'AUCTION_STARTED' ||
        type == 'AUCTION_WON' ||
        type == 'AUCTION_ENDING_SOON') {
      String? auctionId;
      if (data.containsKey('auction_id')) {
        auctionId = data['auction_id'].toString();
      } else if (data.containsKey('id')) {
        auctionId = data['id'].toString();
      } else if (data.containsKey('auctionId')) {
        auctionId = data['auctionId'].toString();
      }

      if (auctionId != null) {
        goRouter.pushNamed(
          RouteConstants.liveAuction,
          pathParameters: {'id': auctionId},
        );
        return;
      }
    } else if (type == 'OUTBID' || type == 'NEW_BID') {
      // Route to adaptive auction details — will show AuctionScreen
      // (pre-auction) or LiveAuctionScreen (live) based on auction state
      String? auctionId;
      if (data.containsKey('auction_id')) {
        auctionId = data['auction_id'].toString();
      } else if (data.containsKey('id')) {
        auctionId = data['id'].toString();
      } else if (data.containsKey('auctionId')) {
        auctionId = data['auctionId'].toString();
      }

      if (auctionId != null) {
        goRouter.pushNamed(
          RouteConstants.auctionDetails,
          pathParameters: {'id': auctionId},
        );
        return;
      }
    } else if (type == 'ORDER_STATUS' || type == 'PAYMENT_APPROVED') {
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

    // Fallbacks
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
    } else if (data.containsKey('order_id') ||
        data.containsKey('orderId') ||
        data['type'] == 'ORDER' ||
        data['type'] == 'ORDER_STATUS') {
      // Navigate to specific order if ID available
      final orderId = data['order_id'] ?? data['orderId'];
      if (orderId != null) {
        goRouter.pushNamed(
          RouteConstants.orderDetails,
          pathParameters: {'id': orderId.toString()},
        );
      } else {
        goRouter.pushNamed(RouteConstants.orders);
      }
    }
  }

  /// Register token after login
  Future<void> registerAfterLogin() async {
    log('registerAfterLogin called', time: DateTime.now(), level: 1);
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    } else {
      log(
        'FCM Token is null in registerAfterLogin, attempting to get it...',
        time: DateTime.now(),
        level: 1,
      );
      await _getToken();
    }
  }

  /// Show a local notification
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

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload ?? '{"type": "local"}',
    );
  }

  /// Show a test notification locally
  Future<void> showTestNotification() async {
    await showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from the app',
      payload: '{"type": "test"}',
    );
  }
}

/// Global instance
final fcmService = FCMService();
