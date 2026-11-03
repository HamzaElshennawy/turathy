import 'dart:async';

import 'server_clock.dart';

/// Fires on the server-second boundary instead of decrementing a local counter.
Timer armServerCountdown({
  required int remainMs,
  required void Function() onTick,
}) {
  return Timer(Duration(milliseconds: nextTickDelay(remainMs)), onTick);
}
