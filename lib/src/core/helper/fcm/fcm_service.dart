import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../features/notifications/data/notifications_repository.dart';
import '../cache/cached_variables.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
  print('Handling background message: ${message.messageId}');
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

    print('FCM Permission status: ${settings.authorizationStatus}');
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
        'turathi_notifications',
        'turathi Notifications',
        description: 'Notifications from turathi app',
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
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    print('FCM Token refreshed: $newToken');
    _fcmToken = newToken;
    await _registerTokenWithBackend(newToken);
  }

  /// Register token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    final userId = CachedVariables.userId;
    if (userId == null) {
      print('User not logged in, skipping token registration');
      return;
    }

    try {
      final platform = Platform.isAndroid ? 'ANDROID' : 'IOS';
      await NotificationsRepository.registerDevice(
        userId: userId,
        token: token,
        platform: platform,
      );
      print('FCM token registered with backend');
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  /// Unregister device token on logout
  Future<void> unregisterDevice() async {
    if (_fcmToken == null) return;

    try {
      await NotificationsRepository.unregisterDevice(_fcmToken!);
      print('FCM token unregistered from backend');
    } catch (e) {
      print('Error unregistering FCM token: $e');
    }
  }

  /// Handle foreground message - show local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'turathi_notifications',
          'turathi Notifications',
          channelDescription: 'Notifications from turathi app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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
    print('Message opened app: ${message.messageId}');
    // TODO: Navigate to specific screen based on message data
    // Example: if message.data['type'] == 'auction', navigate to auction details
  }

  /// Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate based on payload
  }

  /// Register token after login
  Future<void> registerAfterLogin() async {
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    }
  }
}

/// Global instance
final fcmService = FCMService();
