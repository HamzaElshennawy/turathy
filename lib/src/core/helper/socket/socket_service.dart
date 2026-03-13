import 'dart:async';
import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'socket_config.dart';
import 'socket_connection_state.dart';

/// Robust socket service with proper error handling and connection management
class SocketService {
  io.Socket? _socket;
  Timer? _heartbeatTimer;
  Timer? _reconnectionTimer;

  // Track last joined auction so we can re-join on reconnect
  int? _lastJoinedAuctionId;
  int? _lastJoinedUserId;

  // Stream controllers for events
  final Map<String, StreamController<dynamic>> _eventControllers = {};

  // Connection state management
  final StreamController<SocketConnectionStatus> _connectionController =
      StreamController<SocketConnectionStatus>.broadcast();

  SocketConnectionStatus _currentStatus = const SocketConnectionStatus(
    state: SocketConnectionState.disconnected,
  );

  /// Current connection status stream
  Stream<SocketConnectionStatus> get connectionStream =>
      _connectionController.stream;

  /// Current connection status
  SocketConnectionStatus get connectionStatus => _currentStatus;

  /// Whether socket is connected
  bool get isConnected => _currentStatus.isConnected;

  /// Initialize socket connection
  Future<void> connect() async {
    if (_socket?.connected == true) {
      log('Socket already connected');
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

      // Wait for connection with timeout
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
          completer.completeError(TimeoutException('Connection timeout'));
        }
      });

      await completer.future;
    } catch (error) {
      log('Socket connection error: $error');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.failed,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Setup socket event listeners
  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      log('Socket connected successfully');
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

    // Debug: Listen to all events
    _socket!.onAny((event, data) {
      log('SocketService: [DEBUG] Received ANY event: $event, data: $data');
    });

    _socket!.onDisconnect((reason) {
      log('Socket disconnected: $reason');
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
      log('Socket connection error: $error');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.failed,
          errorMessage: error?.toString() ?? 'Connection error',
        ),
      );
    });

    _socket!.onError((error) {
      log('Socket error: $error');
      _addEventData('error', error);
    });

    _socket!.onReconnect((attemptNumber) {
      log('Socket reconnecting (attempt $attemptNumber)');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.reconnecting,
          reconnectionAttempts: attemptNumber as int,
        ),
      );
    });

    _socket!.onReconnectFailed((_) {
      log('Socket reconnection failed permanently');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          state: SocketConnectionState.failed,
          errorMessage: 'Reconnection failed after maximum attempts',
        ),
      );
    });

    // When the socket successfully reconnects, re-join the last auction room
    // so the server sends a fresh auctionSync event — zero polling needed.
    _socket!.onConnect((_) {
      if (_lastJoinedAuctionId != null && _lastJoinedUserId != null) {
        log('SocketService: Reconnected — re-joining auction $_lastJoinedAuctionId');
        emitJoinAuction(_lastJoinedAuctionId!, _lastJoinedUserId!);
      }
    });

    _socket!.onReconnectError((error) {
      log('Socket reconnection error: $error');
      _updateConnectionStatus(
        _currentStatus.copyWith(
          errorMessage: error?.toString() ?? 'Reconnection error',
        ),
      );
    });


  }

  /// Initialize event controllers and listeners
  void _initializeEventControllers() {
    for (final event in SocketConfig.supportedEvents) {
      // Don't overwrite if already created (e.g. by getEventStream before connect)
      if (!_eventControllers.containsKey(event)) {
        _eventControllers[event] = StreamController<dynamic>.broadcast();
      }

      // Always attach the listener to the new socket instance
      _socket?.on(event, (data) {
        log('Received socket event: $event');
        _addEventData(event, data);
      });
    }
  }

  /// Add data to event stream with error handling
  void _addEventData(String event, dynamic data) {
    try {
      final controller = _eventControllers[event];
      if (controller != null && !controller.isClosed) {
        log('SocketService: Adding data to controller for $event');
        controller.add(data);
      } else {
        log('SocketService: Controller for $event is null or closed');
      }
    } catch (error) {
      log('Error adding data to event stream $event: $error');
      // Create error event for this failure
      final errorController = _eventControllers['error'];
      if (errorController != null && !errorController.isClosed) {
        errorController.add({
          'message': 'Failed to process event: $event',
          'originalError': error.toString(),
        });
      }
    }
  }

  /// Get typed stream for specific event
  Stream<T> getEventStream<T>(String eventName, T Function(dynamic) parser) {
    log('SocketService: getEventStream called for $eventName');

    // Check if controller exists, if not, creating it doesn't help if we don't have a listener.
    // However, _initializeEventControllers should have created it if it's in config.
    // If it's dynamic, we might need to add listener here.

    if (!_eventControllers.containsKey(eventName)) {
      log(
        'SocketService: No controller found for $eventName, creating one dynamically.',
      );
      _eventControllers[eventName] = StreamController<dynamic>.broadcast();
      if (_socket != null) {
        _socket!.on(eventName, (data) {
          log('SocketService: Received dynamic event: $eventName data: $data');
          _addEventData(eventName, data);
        });
      }
    }

    final controller = _eventControllers[eventName];
    if (controller == null) {
      throw Exception('No stream controller found for event: $eventName');
    }

    return controller.stream
        .map((data) {
          try {
            return parser(data);
          } catch (error) {
            log('Error parsing event $eventName: $error');
            throw Exception('Failed to parse $eventName event: $error');
          }
        })
        .handleError((error) {
          log('Stream error for $eventName: $error');
        });
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(SocketConnectionStatus newStatus) {
    _currentStatus = newStatus;
    if (!_connectionController.isClosed) {
      _connectionController.add(newStatus);
    }
  }

  /// Start heartbeat to monitor connection
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(SocketConfig.heartbeatInterval, (timer) {
      if (_socket?.connected != true) {
        _stopHeartbeat();
        _updateConnectionStatus(
          _currentStatus.copyWith(
            state: SocketConnectionState.disconnected,
            errorMessage: 'Connection lost during heartbeat',
          ),
        );
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnection() {
    _reconnectionTimer?.cancel();

    if (_currentStatus.reconnectionAttempts >= 5) {
      log('Maximum reconnection attempts reached');
      return;
    }

    final delay = Duration(
      seconds: (2 * _currentStatus.reconnectionAttempts + 1).clamp(1, 30),
    );
    log('Scheduling reconnection in ${delay.inSeconds} seconds');

    _reconnectionTimer = Timer(delay, () {
      if (_socket?.connected != true) {
        log('Attempting to reconnect...');
        connect().catchError((error) {
          log('Reconnection failed: $error');
        });
      }
    });
  }

  // ========== Socket Emit Methods ==========

  /// Emit event with connection check and error handling
  void _safeEmit(String event, Map<String, dynamic> data) {
    if (!isConnected) {
      log('Cannot emit $event: Socket not connected');
      throw Exception('Socket not connected. Cannot emit $event event.');
    }

    try {
      _socket!.emit(event, data);
      log('Emitted $event event: $data');
    } catch (error) {
      log('Error emitting $event: $error');
      throw Exception('Failed to emit $event: $error');
    }
  }

  /// Start live auction
  void emitStartLiveAuction(int auctionId, int userId) {
    _safeEmit('startLiveAuction', {'auctionId': auctionId, 'userId': userId});
  }

  /// Join auction
  void emitJoinAuction(int auctionId, int userId) {
    _lastJoinedAuctionId = auctionId;
    _lastJoinedUserId = userId;
    _safeEmit('joinAuction', {'auctionId': auctionId, 'userId': userId});
  }

  /// Leave auction
  void emitLeaveAuction(int auctionId, int userId) {
    _safeEmit('leaveAuction', {'auctionId': auctionId, 'userId': userId});
  }

  /// Send comment
  void emitComment(int auctionId, int userId, String comment) {
    if (comment.trim().isEmpty) {
      throw ArgumentError('Comment cannot be empty');
    }

    _safeEmit('comment', {
      'auctionId': auctionId,
      'userId': userId,
      'comment': comment.trim(),
    });
  }

  /// Place bid
  void emitPlaceBid(int auctionId, int userId, double amount, int productId) {
    if (amount <= 0) {
      throw ArgumentError('Bid amount must be positive');
    }

    _safeEmit('placeBid', {
      'auctionId': auctionId,
      'userId': userId,
      'amount': amount,
      'productId': productId,
    });
  }

  /// Cancel auction
  void emitCancelAuction(int auctionId, int userId) {
    _safeEmit('cancelAuction', {'auctionId': auctionId, 'userId': userId});
  }

  /// Award auction
  void emitAwardingAuction(int auctionId, int userId, String product) {
    if (product.trim().isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }

    _safeEmit('awardingAuction', {
      'auctionId': auctionId,
      'userId': userId,
      'product': product.trim(),
    });
  }

  /// Change current product
  void emitChangeCurrentProduct({
    required int auctionId,
    required String product,
    required double minBidPrice,
    required double bidPrice,
    required double actualPrice,
  }) {
    if (product.trim().isEmpty) {
      throw ArgumentError('Product name cannot be empty');
    }
    if (minBidPrice < 0 || bidPrice < 0 || actualPrice < 0) {
      throw ArgumentError('Prices cannot be negative');
    }

    _safeEmit('changeCuurentProduct', {
      'auctionId': auctionId,
      'product': product.trim(),
      'minBidPrice': minBidPrice,
      'bidPrice': bidPrice,
      'actualPrice': actualPrice,
    });
  }

  /// Request a fresh auction state snapshot (used by gap-detection logic)
  void emitRequestSync(int auctionId) {
    _safeEmit('requestSync', {'auctionId': auctionId});
  }

  /// Gracefully disconnect socket
  Future<void> disconnect() async {
    log('Disconnecting socket...');

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

  /// Dispose all resources
  void dispose() {
    log('Disposing socket service...');

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
