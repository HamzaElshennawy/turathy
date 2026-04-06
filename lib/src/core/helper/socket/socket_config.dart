/// {@category Core}
///
/// Centralized configuration for the WebSocket connection.
/// 
/// This class defines the connection URL, transport protocols, retry strategies, 
/// and the list of application-level events handled by the [SocketService].
library;

import 'package:socket_io_client/socket_io_client.dart' as io;

/// Configuration constants and helper for [io.Socket] options.
abstract class SocketConfig {
  /// Internal development/staging server IP.
  static String get _baseUrl {
    return 'http://144.91.124.224';
  }

  /// Initial delay (in milliseconds) before the first reconnection attempt.
  static const int _reconnectionDelay = 3000;
  
  /// Total number of automatic reconnection attempts before giving up.
  static const int _maxReconnectionAttempts = 5;
  
  /// General socket timeout (in milliseconds) for the initial handshake.
  static const int _timeout = 20000;

  /// The public URL used to establish the socket connection.
  static String get baseUrl => _baseUrl;

  /// Returns the standardized [io.OptionBuilder] configuration.
  /// 
  /// Constraints:
  /// - Forces 'websocket' transport to avoid slow polling fallbacks.
  /// - Enables automatic reconnection with the defined delay and limit.
  /// - Sets a custom timeout for robustness in poor network conditions.
  static Map<String, dynamic> get options => io.OptionBuilder()
      .setTransports(['websocket'])
      .enableReconnection()
      .setReconnectionDelay(_reconnectionDelay)
      .setReconnectionAttempts(_maxReconnectionAttempts)
      .setTimeout(_timeout)
      .enableAutoConnect()
      .build();

  /// A registry of all server-sent events the application is configured to listen for.
  /// 
  /// These keys are used by [SocketService] to initialize [StreamController]s 
  /// for reactive data binding.
  static const List<String> supportedEvents = [
    // ── Auction Lifecycle ─────────────────────────────────────────────────────
    'auctionPreStarted',    // Sent before the first item goes live
    'auctionStarted',       // Triggered when an auction session begins
    'auction_change_product', // Triggered when switching to a new item
    'auctionCanceled',      // Handle administrative cancellations
    'auctionItemEnded',     // Finalized a single item's bidding
    'auctionEnded',         // Closed the entire auction session
    
    // ── Real-time Updates ─────────────────────────────────────────────────────
    'newBid',               // Incoming bid from any participant
    'userCountUpdate',      // Number of active viewers updated
    'newComment',           // Social commentary from other users
    'auctionSync',          // State synchronization for late-joiners
    'auctionStateUpdate',   // General metadata updates (e.g., timer sync)
    
    // ── Error Handling ────────────────────────────────────────────────────────
    'bidRejected',          // Validation error for the current user's bid
    'error',                // Generic server-side socket errors
  ];

  /// The maximum duration to wait for the initial connection acknowledge.
  static const Duration connectionTimeout = Duration(seconds: 20);

  /// Interval at which the app checks if the socket is still internally 'connected'.
  static const Duration heartbeatInterval = Duration(seconds: 30);
}

