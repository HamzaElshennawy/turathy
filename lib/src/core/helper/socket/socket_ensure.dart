/// Thrown when an emit is attempted while the live socket is offline.
class SocketOfflineException implements Exception {
  /// Human-readable reason (kept in English for logs; UI maps via l10n).
  final String message;

  const SocketOfflineException([
    this.message = 'Socket offline. Cannot emit.',
  ]);

  @override
  String toString() => message;
}

/// Connects if needed, then fails closed so callers never emit while offline.
///
/// [connect] must rethrow on handshake failure (not swallow).
Future<void> ensureSocketConnected({
  required bool Function() isConnected,
  required Future<void> Function() connect,
}) async {
  if (isConnected()) return;
  await connect();
  if (!isConnected()) {
    throw const SocketOfflineException();
  }
}
