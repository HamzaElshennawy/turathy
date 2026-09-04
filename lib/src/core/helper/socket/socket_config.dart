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
  /// Secure public host for WebSocket connections.
  static String get _baseUrl {
    return 'https://api.alturathaljmeel.com.sa';
  }

  /// Initial delay (in milliseconds) before the first reconnection attempt.
  static const int _reconnectionDelay = 1500;

  /// Cap for engine backoff (milliseconds).
  static const int _reconnectionDelayMax = 10000;

  /// Engine reconnection attempts (engine is the sole reconnect owner).
  static const int _maxReconnectionAttempts = 50;

  /// General socket timeout (in milliseconds) for the initial handshake.
  static const int _timeout = 20000;

  /// The public URL used to establish the socket connection.
  static String get baseUrl => _baseUrl;

  /// Returns the standardized [io.OptionBuilder] configuration.
  static Map<String, dynamic> optionsFor({String? token}) {
    final builder = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableReconnection()
        .setReconnectionDelay(_reconnectionDelay)
        .setReconnectionDelayMax(_reconnectionDelayMax)
        .setReconnectionAttempts(_maxReconnectionAttempts)
        .setTimeout(_timeout)
        .enableAutoConnect();
    if (token != null && token.isNotEmpty) {
      builder.setAuth({'token': token});
      builder.setExtraHeaders({'Authorization': 'Bearer $token'});
    }
    return builder.build();
  }

  static Map<String, dynamic> get options => optionsFor();

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
    'timerExtended',        // Anti-snipe / admin lot timer bump
    'userCountUpdate',      // Number of active viewers updated
    'newComment',           // Social commentary from other users
    'auctionSync',          // State synchronization for late-joiners
    'auctionStateUpdate',   // General metadata updates (e.g., timer sync)

    // ── Error Handling ────────────────────────────────────────────────────────
    'bidAccepted',          // ACK for the current user's accepted bid
    'bidRejected',          // Validation error for the current user's bid
    'error',                // Generic server-side socket errors
  ];

  /// The maximum duration to wait for the initial connection acknowledge.
  static const Duration connectionTimeout = Duration(seconds: 20);

  /// Interval at which the app checks if the socket is still internally 'connected'.
  static const Duration heartbeatInterval = Duration(seconds: 30);
}
