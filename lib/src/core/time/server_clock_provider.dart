import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'server_clock.dart';

/// Shared auction clock. Widgets read [serverClock] directly; this provider
/// exists so Riverpod listeners can depend on the same instance.
final serverClockProvider = Provider<ServerClock>((ref) => serverClock);
