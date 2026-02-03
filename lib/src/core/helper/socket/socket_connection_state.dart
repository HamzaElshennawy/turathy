/// Represents the current state of socket connection
enum SocketConnectionState {
  /// Socket is disconnected
  disconnected,

  /// Socket is attempting to connect
  connecting,

  /// Socket is connected and ready
  connected,

  /// Socket is reconnecting after a disconnection
  reconnecting,

  /// Socket connection failed permanently
  failed,
}

/// Socket connection status with additional information
class SocketConnectionStatus {
  final SocketConnectionState state;
  final String? errorMessage;
  final int reconnectionAttempts;
  final DateTime? lastConnectionTime;
  final DateTime? lastDisconnectionTime;

  const SocketConnectionStatus({
    required this.state,
    this.errorMessage,
    this.reconnectionAttempts = 0,
    this.lastConnectionTime,
    this.lastDisconnectionTime,
  });

  /// Creates a copy with updated fields
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

  /// Whether the socket is currently connected
  bool get isConnected => state == SocketConnectionState.connected;

  /// Whether the socket is in a connecting state
  bool get isConnecting =>
      state == SocketConnectionState.connecting ||
      state == SocketConnectionState.reconnecting;

  /// Whether the socket has permanently failed
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
