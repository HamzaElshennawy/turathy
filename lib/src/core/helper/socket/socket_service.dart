/// {@category Core}
///
/// A robust service for managing real-time bidirectional communication via WebSockets.
/// 
/// This service wraps the `socket_io_client` package to provide:
/// - Automatic reconnection with exponential backoff strategies.
/// - Heartbeat monitoring to detect silent connection drops or network jitter.
/// - Stream-based event handling with typed parsing for domain models.
/// - Global connection state tracking for reactive UI feedback.
/// - Specialized emit methods for auction-specific actions (bidding, joining, sync).
library;

import 'dart:async';
import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'socket_config.dart';
import 'socket_connection_state.dart';

/// The central authority for the application's WebSocket lifecycle and event distribution.
/// 
/// Manages a single [io.Socket] instance, providing a high-level API for 
/// features to subscribe to real-time events without managing raw socket listeners.
class SocketService {
  /// The underlying Socket.IO client instance.
  io.Socket? _socket;
  
  /// Timer used to periodically check if the connection is still alive (Heartbeat).
  Timer? _heartbeatTimer;
  
  /// Timer used to manage delayed reconnection attempts using backoff logic.
  Timer? _reconnectionTimer;

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
  Future<void> connect() async {
    if (_socket?.connected == true) {
      log('SocketService: Already connected');
      return;
    }

    try {
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.connecting,
          errorMessage: null,
        ),
      );

      _socket = io.io(SocketConfig.baseUrl, SocketConfig.options);
      _setupSocketListeners();
      _initializeEventControllers();

      // Manual timeout handling for the initial connection handshake
      final completer = Completer<void>();
      Timer? timeoutTimer;

      void onConnected() {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }

      void onConnectionError(dynamic error) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      }

      _socket!.onConnect((_) => onConnected());
      _socket!.onConnectError((error) => onConnectionError(error));
      _socket!.onError((error) => onConnectionError(error));

      timeoutTimer = Timer(SocketConfig.connectionTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Socket connection timeout after ${SocketConfig.connectionTimeout.inSeconds}s'));
        }
      });

      await completer.future;
    } catch (error) {
      log('SocketService: Connection error: $error');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.failed,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Internal: Configures core Socket.IO lifecycle event listeners.
  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      log('SocketService: Connected successfully');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.connected,
          lastConnectionTime: DateTime.now(),
          errorMessage: null,
          reconnectionAttempts: 0,
        ),
      );
      _startHeartbeat();
    });

    // Debugging: Log all incoming raw traffic during development
    _socket!.onAny((event, data) {
      log('SocketService: [DEBUG] Incoming: $event -> $data');
    });

    _socket!.onDisconnect((reason) {
      log('SocketService: Disconnected (Reason: $reason)');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.disconnected,
          lastDisconnectionTime: DateTime.now(),
          errorMessage: reason?.toString(),
        ),
      );
      _stopHeartbeat();
      _scheduleReconnection();
    });

    _socket!.onConnectError((error) {
      log('SocketService: Connection error: $error');
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

    // Re-synchronization: Automatically rejoin last auction on successful connect
    _socket!.onConnect((_) {
      if (_lastJoinedAuctionId != null && _lastJoinedUserId != null) {
        log('SocketService: Restoring auction session for ID: $_lastJoinedAuctionId');
        emitJoinAuction(_lastJoinedAuctionId!, _lastJoinedUserId!);
      }
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
      if (_socket?.connected != true) {
        log('SocketService: Heartbeat detected silent disconnection');
        _stopHeartbeat();
        _updateConnectionStatus(
          _currentStatus.copyWith(
            state: SocketConnectionState.disconnected,
            errorMessage: 'Heartbeat failure',
          ),
        );
      }
    });
  }

  /// Internal: Stops and clears the heartbeat monitor.
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Internal: Implements an exponential backoff strategy for reconnection tasks.
  void _scheduleReconnection() {
    _reconnectionTimer?.cancel();

    if (_currentStatus.reconnectionAttempts >= 5) {
      log('SocketService: Halting reconnection after 5 failed attempts');
      return;
    }

    // Progression: 1s, 3s, 5s... capped at 30s
    final delay = Duration(
      seconds: (2 * _currentStatus.reconnectionAttempts + 1).clamp(1, 30),
    );
    log('SocketService: Reconnection scheduled in ${delay.inSeconds}s');

    _reconnectionTimer = Timer(delay, () {
      if (_socket?.connected != true) {
        log('SocketService: Executing scheduled reconnection...');
        connect().catchError((error) {
          log('SocketService: Execution failure: $error');
        });
      }
    });
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
  void emitPlaceBid(int auctionId, int userId, double amount, int productId) {
    if (amount <= 0) {
      throw ArgumentError('Bid amount must be a positive non-zero value');
    }

    _safeEmit('placeBid', {
      'auctionId': auctionId,
      'userId': userId,
      'amount': amount,
      'productId': productId,
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

  /// Manually requests an authoritative state snapshot from the server.
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

    _stopHeartbeat();
    _reconnectionTimer?.cancel();

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _updateConnectionStatus(
      _currentStatus.copyWith(
        state: SocketConnectionState.disconnected,
        lastDisconnectionTime: DateTime.now(),
      ),
    );
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
  }
}

