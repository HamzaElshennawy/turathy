/// {@category Core}
///
/// A convenience library providing a single point of entry for all WebSocket-related types.
/// 
/// Consolidates configurations, service classes, status models, and Riverpod 
/// providers to simplify feature-level imports.
library core.socket;

// Core socket service and state management
export 'socket_config.dart';
export 'socket_connection_state.dart';
export 'socket_models.dart';
export 'socket_providers.dart';
export 'socket_service.dart';

// UI components for connection feedback
export '../../common_widgets/socket_connection_indicator.dart';

