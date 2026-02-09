import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helper/socket/socket_connection_state.dart';
import '../helper/socket/socket_providers.dart';

/// Widget that displays socket connection status to users
class SocketConnectionIndicator extends ConsumerWidget {
  final Widget child;
  final bool showIndicator;
  final EdgeInsets padding;

  const SocketConnectionIndicator({
    required this.child,
    this.showIndicator = true,
    this.padding = const EdgeInsets.only(top: 4),
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showIndicator) return child;

    final connectionStatus = ref.watch(socketConnectionProvider);

    return connectionStatus.when(
      data: (status) => Column(
        children: [
          if (status.state != SocketConnectionState.connected) ...[
            _buildConnectionBanner(context, status),
            SizedBox(height: padding.top),
          ],
          Expanded(child: child),
        ],
      ),
      loading: () => child,
      error: (error, _) => Column(
        children: [
          _buildErrorBanner(context, error.toString()),
          SizedBox(height: padding.top),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(
    BuildContext context,
    SocketConnectionStatus status,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status.state),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _getStatusIcon(status.state),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusTitle(status.state),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (status.errorMessage != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      status.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (status.state == SocketConnectionState.reconnecting) ...[
                    const SizedBox(height: 2),
                    Text(
                      'محاولة ${status.reconnectionAttempts + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (status.state == SocketConnectionState.connecting ||
                status.state == SocketConnectionState.reconnecting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'خطأ في الاتصال: $error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connecting:
        return Colors.blue;
      case SocketConnectionState.reconnecting:
        return Colors.orange;
      case SocketConnectionState.disconnected:
        return Colors.grey;
      case SocketConnectionState.failed:
        return Colors.red;
      case SocketConnectionState.connected:
        return Colors.green;
    }
  }

  Widget _getStatusIcon(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connecting:
        return const Icon(Icons.wifi_1_bar, color: Colors.white, size: 20);
      case SocketConnectionState.reconnecting:
        return const Icon(Icons.refresh, color: Colors.white, size: 20);
      case SocketConnectionState.disconnected:
        return const Icon(Icons.wifi_off, color: Colors.white, size: 20);
      case SocketConnectionState.failed:
        return const Icon(Icons.error_outline, color: Colors.white, size: 20);
      case SocketConnectionState.connected:
        return const Icon(Icons.wifi, color: Colors.white, size: 20);
    }
  }

  String _getStatusTitle(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connecting:
        return 'جاري الاتصال...';
      case SocketConnectionState.reconnecting:
        return 'جاري إعادة الاتصال...';
      case SocketConnectionState.disconnected:
        return 'انقطع الاتصال';
      case SocketConnectionState.failed:
        return 'فشل الاتصال';
      case SocketConnectionState.connected:
        return 'متصل';
    }
  }
}

/// Floating connection status indicator
class FloatingConnectionIndicator extends ConsumerWidget {
  const FloatingConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(socketConnectionProvider);

    return connectionStatus.when(
      data: (status) {
        if (status.state == SocketConnectionState.connected) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(status.state),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getStatusIcon(status.state),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(status.state),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (status.state == SocketConnectionState.connecting ||
                      status.state == SocketConnectionState.reconnecting) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Color _getStatusColor(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connecting:
        return Colors.blue;
      case SocketConnectionState.reconnecting:
        return Colors.orange;
      case SocketConnectionState.disconnected:
        return Colors.grey.shade600;
      case SocketConnectionState.failed:
        return Colors.red;
      case SocketConnectionState.connected:
        return Colors.green;
    }
  }

  Widget _getStatusIcon(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connecting:
        return const Icon(Icons.wifi_1_bar, color: Colors.white, size: 16);
      case SocketConnectionState.reconnecting:
        return const Icon(Icons.refresh, color: Colors.white, size: 16);
      case SocketConnectionState.disconnected:
        return const Icon(Icons.wifi_off, color: Colors.white, size: 16);
      case SocketConnectionState.failed:
        return const Icon(Icons.error_outline, color: Colors.white, size: 16);
      case SocketConnectionState.connected:
        return const Icon(Icons.wifi, color: Colors.white, size: 16);
    }
  }

  String _getStatusText(SocketConnectionState state) {
    switch (state) {
      case SocketConnectionState.connecting:
        return 'جاري الاتصال';
      case SocketConnectionState.reconnecting:
        return 'إعادة اتصال';
      case SocketConnectionState.disconnected:
        return 'غير متصل';
      case SocketConnectionState.failed:
        return 'فشل الاتصال';
      case SocketConnectionState.connected:
        return 'متصل';
    }
  }
}
