import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket configuration class for managing connection settings
abstract class SocketConfig {
  //static const String _baseUrl = 'wss://backend.barakkh.sa/';
  static String get _baseUrl {
    if (kIsWeb) return 'ws://localhost:4005/';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'wss://10.0.2.2:4005/';
    }
    return 'ws://localhost:4005/';
  }

  static const int _reconnectionDelay = 3000;
  static const int _maxReconnectionAttempts = 5;
  static const int _timeout = 20000;

  /// Production socket URL
  static String get baseUrl => _baseUrl;

  /// Socket.IO options configuration
  static Map<String, dynamic> get options => io.OptionBuilder()
      .setTransports(['websocket'])
      .enableReconnection()
      .setReconnectionDelay(_reconnectionDelay)
      .setReconnectionAttempts(_maxReconnectionAttempts)
      .setTimeout(_timeout)
      .enableAutoConnect()
      .build();

  /// Socket events that the app listens to
  static const List<String> supportedEvents = [
    'auctionStarted',
    'userCountUpdate',
    'newComment',
    'newBid',
    'auctionCanceled',
    'auctionEnded',
    'auction_change_product',
    'error',
  ];

  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 20);

  /// Heartbeat interval for connection monitoring
  static const Duration heartbeatInterval = Duration(seconds: 30);
}
