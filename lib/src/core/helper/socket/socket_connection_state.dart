/// {@category Core}
///
/// Defines the various states of the WebSocket lifecycle.
/// 
/// These states are used to drive UI indicators (e.g., connection banners, 
/// bidding button availability) and to manage internal reconnection logic.
library;

/// High-level states for a network socket connection.
enum SocketConnectionState {
  /// The initial state or after a manual disconnect.
  disconnected,

  /// Currently performing the initial handshake with the server.
  connecting,

  /// Connection established and data transmission is possible.
  connected,

  /// Lost connection unexpectedly; currently in an automatic retry loop.
  reconnecting,

  /// Exhausted all retry attempts or encountered a fatal configuration error.
  failed,
}

/// {@category Core}
///
/// A data model representing the comprehensive status of the socket connection.
/// 
/// Combines the raw [state] with metadata like error messages, 
/// reconnection attempt counts, and timestamps for debugging and UI feedback.
class SocketConnectionStatus {
  /// The high-level state of the connection (e.g. connected, connecting).
  final SocketConnectionState state;
  
  /// The raw error message from the underlying engine if a failure occurred.
  final String? errorMessage;
  
  /// The current index of reconnection attempt (resets on successful connect).
  final int reconnectionAttempts;
  
  /// Timestamp of the last successful 'onConnect' event.
  final DateTime? lastConnectionTime;
  
  /// Timestamp of the last 'onDisconnect' event.
  final DateTime? lastDisconnectionTime;

  /// Default constructor for creating a status snapshot.
  const SocketConnectionStatus({
    required this.state,
    this.errorMessage,
    this.reconnectionAttempts = 0,
    this.lastConnectionTime,
    this.lastDisconnectionTime,
  });

  /// Returns a new instance with override values, preserving existing ones where null.
  SocketConnectionStatus copyWith({
    SocketConnectionState? state,
    String? errorMessage,
    int? reconnectionAttempts,
    DateTime? lastConnectionTime,
    DateTime? lastDisconnectionTime,
  }) {
    return SocketConnectionStatus(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      reconnectionAttempts: reconnectionAttempts ?? this.reconnectionAttempts,
      lastConnectionTime: lastConnectionTime ?? this.lastConnectionTime,
      lastDisconnectionTime:
          lastDisconnectionTime ?? this.lastDisconnectionTime,
    );
  }

  /// Helper: True if the socket is actively connected and ready for data.
  bool get isConnected => state == SocketConnectionState.connected;

  /// Helper: True if a connection process is in progress (initial or retry).
  bool get isConnecting =>
      state == SocketConnectionState.connecting ||
      state == SocketConnectionState.reconnecting;

  /// Helper: True if no further automatic connection attempts will be made.
  bool get hasFailed => state == SocketConnectionState.failed;

  @override
  String toString() {
    return 'SocketConnectionStatus(state: $state, error: $errorMessage, attempts: $reconnectionAttempts)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocketConnectionStatus &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          errorMessage == other.errorMessage &&
          reconnectionAttempts == other.reconnectionAttempts;

  @override
  int get hashCode =>
      state.hashCode ^ errorMessage.hashCode ^ reconnectionAttempts.hashCode;
}
