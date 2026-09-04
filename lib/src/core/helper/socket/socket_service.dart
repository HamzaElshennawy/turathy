/// {@category Core}
///
/// A robust service for managing real-time bidirectional communication via WebSockets.
///
/// This service wraps the `socket_io_client` package to provide:
/// - Engine-owned automatic reconnection (single [io.Socket] instance).
/// - Heartbeat monitoring that requests reconnect instead of going silent.
/// - Stream-based event handling with typed parsing for domain models.
/// - Global connection state tracking for reactive UI feedback.
/// - Specialized emit methods for auction-specific actions (bidding, joining, sync).
library;

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'socket_config.dart';
import 'socket_connection_state.dart';

/// The central authority for the application's WebSocket lifecycle and event distribution.
///
/// Manages a single [io.Socket] instance, providing a high-level API for
/// features to subscribe to real-time events without managing raw socket listeners.
class SocketService {
  static SocketService? active;

  SocketService() {
    active = this;
  }

  /// The underlying Socket.IO client instance.
  io.Socket? _socket;

  /// Timer used to periodically check if the connection is still alive (Heartbeat).
  Timer? _heartbeatTimer;

  /// Cached ID of the last auction room joined, used for automatic re-joining on reconnect.
  int? _lastJoinedAuctionId;

  /// Cached ID of the current user, used for authenticated re-joining on reconnect.
  int? _lastJoinedUserId;

  /// A map of broadcast stream controllers, indexed by event name.
  final Map<String, StreamController<dynamic>> _eventControllers = {};

  /// Internal broadcast controller for notifying the UI of connection status changes.
  final StreamController<SocketConnectionStatus> _connectionController =
      StreamController<SocketConnectionStatus>.broadcast();

  /// Internal tracking of the current connection status snapshot.
  SocketConnectionStatus _currentStatus = const SocketConnectionStatus(
    state: SocketConnectionState.disconnected,
  );

  /// Completes when the current [connect] handshake succeeds or fails.
  Completer<void>? _handshake;

  /// Single-flight lock so MainScreen / join / bid share one handshake.
  Future<void>? _inFlight;

  /// True after an explicit [disconnect]; engine must not be treated as a drop.
  bool _manualDisconnect = false;

  bool _lifecycleListenersAttached = false;
  bool _eventListenersAttached = false;

  /// A public stream of [SocketConnectionStatus] updates.
  Stream<SocketConnectionStatus> get connectionStream =>
      _connectionController.stream;

  /// Gets the current [SocketConnectionStatus] snapshot.
  SocketConnectionStatus get connectionStatus => _currentStatus;

  /// Returns true if the socket is currently in a [SocketConnectionState.connected] state.
  bool get isConnected => _currentStatus.isConnected;

  /// Establishes a connection to the WebSocket server using [SocketConfig].
  ///
  /// Returns a [Future] that completes when the connection is established.
  /// Throws a [TimeoutException] if the handshake takes longer than
  /// [SocketConfig.connectionTimeout].
  Future<void> connect() {
    if (_socket?.connected == true) {
      _markConnected();
      return Future.value();
    }
    _inFlight ??= _connectInternal().whenComplete(() {
      _inFlight = null;
    });
    return _inFlight!;
  }

  Future<void> _connectInternal() async {
    if (_socket?.connected == true) {
      _markConnected();
      return;
    }

    _manualDisconnect = false;
    _updateConnectionStatus(
      _currentStatus.copyWith(
        state: SocketConnectionState.connecting,
        errorMessage: null,
      ),
    );

    final handshake = Completer<void>();
    _handshake = handshake;

    if (_socket == null) {
      _socket = io.io(
        SocketConfig.baseUrl,
        SocketConfig.optionsFor(token: CachedVariables.token),
      );
      _setupSocketListeners();
      _initializeEventControllers();
    } else {
      _socket!.connect();
    }

    if (_socket?.connected == true) {
      _markConnected();
      if (!handshake.isCompleted) {
        handshake.complete();
      }
      return;
    }

    try {
      await handshake.future.timeout(SocketConfig.connectionTimeout);
    } on TimeoutException {
      log('SocketService: Connection timeout');
      if (identical(_handshake, handshake)) {
        _updateConnectionStatus(
          _currentStatus.copyWith(
            state: SocketConnectionState.failed,
            errorMessage:
                'Socket connection timeout after ${SocketConfig.connectionTimeout.inSeconds}s',
          ),
        );
      }
      rethrow;
    } catch (error) {
      log('SocketService: Connection error: $error');
      if (identical(_handshake, handshake)) {
        _updateConnectionStatus(
          _currentStatus.copyWith(
            state: SocketConnectionState.failed,
            errorMessage: error.toString(),
          ),
        );
      }
      rethrow;
    }
  }

  void _markConnected() {
    _updateConnectionStatus(
      _currentStatus.copyWith(
        state: SocketConnectionState.connected,
        lastConnectionTime: DateTime.now(),
        errorMessage: null,
        reconnectionAttempts: 0,
      ),
    );
  }

  void _rejoinCachedAuction() {
    if (_lastJoinedAuctionId == null || _lastJoinedUserId == null) return;
    try {
      log(
        'SocketService: Restoring auction session for ID: $_lastJoinedAuctionId',
      );
      emitJoinAuction(_lastJoinedAuctionId!, _lastJoinedUserId!);
    } catch (error) {
      log('SocketService: Rejoin emit failed: $error');
    }
  }

  /// Internal: Configures core Socket.IO lifecycle event listeners.
  void _setupSocketListeners() {
    if (_socket == null || _lifecycleListenersAttached) return;
    _lifecycleListenersAttached = true;

    _socket!.onConnect((_) {
      log('SocketService: Connected successfully');
      _markConnected();
      _startHeartbeat();
      if (_handshake != null && !_handshake!.isCompleted) {
        _handshake!.complete();
      }
      _rejoinCachedAuction();
    });

    // Debugging: Log all incoming raw traffic during development
    if (kDebugMode) {
      _socket!.onAny((event, data) {
        log('SocketService: [DEBUG] Incoming: $event -> $data');
      });
    }

    _socket!.onDisconnect((reason) {
      log('SocketService: Disconnected (Reason: $reason)');
      _stopHeartbeat();
      if (_manualDisconnect) {
        _updateConnectionStatus(
          _currentStatus.copyWith(
            state: SocketConnectionState.disconnected,
            lastDisconnectionTime: DateTime.now(),
            errorMessage: reason?.toString(),
          ),
        );
        return;
      }
      // Engine reconnection is the sole retry owner — do not io.io() again.
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.reconnecting,
          lastDisconnectionTime: DateTime.now(),
          errorMessage: reason?.toString(),
        ),
      );
    });

    _socket!.onConnectError((error) {
      log('SocketService: Connection error: $error');
      if (_handshake != null && !_handshake!.isCompleted) {
        _handshake!.completeError(error ?? 'Connection error');
      }
      if (_manualDisconnect) return;
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.failed,
          errorMessage: error?.toString() ?? 'Connection error',
        ),
      );
    });

    _socket!.onError((error) {
      log('SocketService: General error: $error');
      _addEventData('error', error);
    });

    _socket!.onReconnect((attemptNumber) {
      log('SocketService: Reconnecting (Attempt #$attemptNumber)');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.reconnecting,
          reconnectionAttempts: attemptNumber as int,
        ),
      );
    });

    _socket!.onReconnectFailed((_) {
      log('SocketService: Reconnection failed permanently');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.failed,
          errorMessage: 'Maximum reconnection attempts exceeded',
        ),
      );
    });

    _socket!.onReconnectError((error) {
      log('SocketService: Reconnection error: $error');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          errorMessage: error?.toString() ?? 'Reconnection error',
        ),
      );
    });
  }

  /// Internal: Initializes controllers for all events defined in [SocketConfig].
  void _initializeEventControllers() {
    for (final event in SocketConfig.supportedEvents) {
      if (!_eventControllers.containsKey(event)) {
        _eventControllers[event] = StreamController<dynamic>.broadcast();
      }
    }

    if (_eventListenersAttached || _socket == null) return;
    _eventListenersAttached = true;

    for (final event in SocketConfig.supportedEvents) {
      _socket?.on(event, (data) {
        _addEventData(event, data);
      });
    }
  }

  /// Internal: Routes raw data payloads to the correct high-level event stream.
  void _addEventData(String event, dynamic data) {
    try {
      final controller = _eventControllers[event];
      if (controller != null && !controller.isClosed) {
        controller.add(data);
      }
    } catch (error) {
      log('SocketService: Error routing event $event: $error');
      final errorController = _eventControllers['error'];
      if (errorController != null && !errorController.isClosed) {
        errorController.add({
          'message': 'Routing failure for event: $event',
          'details': error.toString(),
        });
      }
    }
  }

  /// Returns a typed stream for a specific socket event.
  ///
  /// - [eventName]: The key used by the server to emit the event (e.g. 'newBid').
  /// - [parser]: A transformer function that converts raw dynamic data into a type [T].
  Stream<T> getEventStream<T>(String eventName, T Function(dynamic) parser) {
    if (!_eventControllers.containsKey(eventName)) {
      _eventControllers[eventName] = StreamController<dynamic>.broadcast();
      _socket?.on(eventName, (data) => _addEventData(eventName, data));
    }

    final controller = _eventControllers[eventName];
    if (controller == null) {
      throw Exception('Controller registry failure for event: $eventName');
    }

    return controller.stream
        .map((data) {
          try {
            return parser(data);
          } catch (error) {
            log('SocketService: Parsing error on $eventName: $error');
            throw Exception('Model parsing failure for $eventName: $error');
          }
        })
        .handleError((error) {
          log('SocketService: Stream error on $eventName: $error');
        });
  }

  /// Internal: Notifies connection listeners of a state transition.
  void _updateConnectionStatus(SocketConnectionStatus newStatus) {
    _currentStatus = newStatus;
    if (!_connectionController.isClosed) {
      _connectionController.add(newStatus);
    }
  }

  /// Internal: Monitors the socket's internal `connected` property periodically.
  ///
  /// This bridges gaps where the underlying library fails to emit disconnect events
  /// during specific network failure modes (e.g., DNS timeout).
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(SocketConfig.heartbeatInterval, (timer) {
      if (_manualDisconnect) return;
      if (_socket?.connected == true) return;
      log('SocketService: Heartbeat detected silent disconnection');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.reconnecting,
          errorMessage: 'Heartbeat failure',
        ),
      );
      _socket?.connect();
    });
  }

  /// Internal: Stops and clears the heartbeat monitor.
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ========== Socket Emit Methods (Command Pattern) ==========

  /// Internal: Central gatekeeper for all outward emissions, ensuring active connectivity.
  void _safeEmit(String event, Map<String, dynamic> data) {
    if (!isConnected) {
      log('SocketService: Emit rejected — not connected ($event)');
      throw Exception('Socket offline. Cannot emit $event.');
    }

    try {
      _socket!.emit(event, data);
      log('SocketService: Emitted $event');
    } catch (error) {
      log('SocketService: Emission failure for $event: $error');
      throw Exception('Failed to transmit $event: $error');
    }
  }

  /// Commands the server to transition an auction to its active live state.
  void emitStartLiveAuction(int auctionId, int userId) {
    _safeEmit('startLiveAuction', {'auctionId': auctionId, 'userId': userId});
  }

  /// Joins a specific auction room to receive its focused event stream.
  ///
  /// Automatically caches [auctionId] and [userId] for session recovery.
  void emitJoinAuction(int auctionId, int userId) {
    _lastJoinedAuctionId = auctionId;
    _lastJoinedUserId = userId;
    _safeEmit('joinAuction', {'auctionId': auctionId, 'userId': userId});
  }

  /// Signals intention to stop receiving updates for a specific auction room.
  void emitLeaveAuction(int auctionId, int userId) {
    _safeEmit('leaveAuction', {'auctionId': auctionId, 'userId': userId});
  }

  /// Transmits a textual comment to the auction's shared chat namespace.
  void emitComment(int auctionId, int userId, String comment) {
    if (comment.trim().isEmpty) {
      throw ArgumentError('Comment content cannot be empty');
    }

    _safeEmit('comment', {
      'auctionId': auctionId,
      'userId': userId,
      'comment': comment.trim(),
    });
  }

  /// Submits a competitive bid for an item within an active auction.
  void emitPlaceBid(
    int auctionId,
    int userId,
    double amount,
    int productId, {
    String? clientBidId,
  }) {
    if (amount <= 0) {
      throw ArgumentError('Bid amount must be a positive non-zero value');
    }

    _safeEmit('placeBid', {
      'auctionId': auctionId,
      'userId': userId,
      'amount': amount,
      'productId': productId,
      if (clientBidId != null) 'clientBidId': clientBidId,
    });
  }

  /// Performs an administrative shutdown of the specified auction session.
  void emitCancelAuction(int auctionId, int userId) {
    _safeEmit('cancelAuction', {'auctionId': auctionId, 'userId': userId});
  }

  /// Officially declares a winner for the specified product item.
  void emitAwardingAuction(int auctionId, int userId, String product) {
    if (product.trim().isEmpty) {
      throw ArgumentError('Product name identifier cannot be empty');
    }

    _safeEmit('awardingAuction', {
      'auctionId': auctionId,
      'userId': userId,
      'product': product.trim(),
    });
  }

  /// Admin: Updates the metadata for the product unit currently under bidding.
  void emitChangeCurrentProduct({
    required int auctionId,
    required String product,
    required double minBidPrice,
    required double bidPrice,
    required double actualPrice,
  }) {
    if (product.trim().isEmpty) {
      throw ArgumentError('Product identifier cannot be empty');
    }
    if (minBidPrice < 0 || bidPrice < 0 || actualPrice < 0) {
      throw ArgumentError('Auction pricing cannot be negative');
    }

    _safeEmit('changeCuurentProduct', {
      'auctionId': auctionId,
      'product': product.trim(),
      'minBidPrice': minBidPrice,
      'bidPrice': bidPrice,
      'actualPrice': actualPrice,
    });
  }

  /// Manually requests an authoritative state snapshot from the backend.
  ///
  /// Essential for resetting local UI state after network gaps or sequence errors.
  void emitRequestSync(int auctionId) {
    _safeEmit('requestSync', {'auctionId': auctionId});
  }

  /// Transmits the client’s local wall clock time for server-side latency calculation.
  void emitClientTimeSync() {
    _safeEmit('clientTimeSync', {
      'clientTime': DateTime.now().toIso8601String(),
    });
  }

  /// Gracefully terminates the socket connection and background tasks.
  Future<void> disconnect() async {
    log('SocketService: Disconnecting session...');

    _manualDisconnect = true;
    _stopHeartbeat();

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _lifecycleListenersAttached = false;
    _eventListenersAttached = false;
    _handshake = null;

    _updateConnectionStatus(
      _currentStatus.copyWith(
        state: SocketConnectionState.disconnected,
        lastDisconnectionTime: DateTime.now(),
      ),
    );
  }

  /// Recreate the engine after login, logout, or token refresh.
  Future<void> reconnectWithAuth() async {
    final auctionId = _lastJoinedAuctionId;
    final userId = _lastJoinedUserId;
    await disconnect();
    await connect();
    if (auctionId != null && userId != null) {
      emitJoinAuction(auctionId, userId);
      emitRequestSync(auctionId);
    }
  }

  /// Shuts down all stream controllers and permanently disposes the service.
  void dispose() {
    log('SocketService: Disposing entire service registry...');

    disconnect();

    for (final controller in _eventControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _eventControllers.clear();

    if (!_connectionController.isClosed) {
      _connectionController.close();
    }
    if (identical(active, this)) {
      active = null;
    }
  }
}
