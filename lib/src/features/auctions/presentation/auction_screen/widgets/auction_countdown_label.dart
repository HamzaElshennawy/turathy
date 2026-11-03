import 'dart:async';

import 'package:flutter/material.dart';
import 'package:turathy/src/core/time/server_clock.dart';
import 'package:turathy/src/core/time/server_countdown.dart';

/// Isolated countdown label so the parent auction screen does not rebuild every second.
class AuctionCountdownLabel extends StatefulWidget {
  final DateTime target;
  final String? suffix;
  final TextStyle? style;

  const AuctionCountdownLabel({
    super.key,
    required this.target,
    this.suffix,
    this.style,
  });

  /// Same formatting as the former `_formatDuration` on [AuctionScreen].
  static String formatDuration(Duration duration) {
    return formatClockDuration(duration.inMilliseconds);
  }

  @override
  State<AuctionCountdownLabel> createState() => _AuctionCountdownLabelState();
}

class _AuctionCountdownLabelState extends State<AuctionCountdownLabel> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _arm();
  }

  @override
  void didUpdateWidget(covariant AuctionCountdownLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _timer?.cancel();
      _remaining = _computeRemaining();
      if (_remaining > Duration.zero) {
        _arm();
      }
    }
  }

  void _arm() {
    _timer?.cancel();
    if (_remaining <= Duration.zero) return;
    _timer = armServerCountdown(
      remainMs: _remaining.inMilliseconds,
      onTick: () {
        if (!mounted) return;
        final next = _computeRemaining();
        setState(() => _remaining = next);
        if (next <= Duration.zero) return;
        _arm();
      },
    );
  }

  Duration _computeRemaining() {
    final difference = widget.target.difference(serverClock.nowDate());
    return difference.isNegative ? Duration.zero : difference;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= Duration.zero) {
      return const SizedBox.shrink();
    }
    final suffix = widget.suffix;
    final text = suffix == null || suffix.isEmpty
        ? AuctionCountdownLabel.formatDuration(_remaining)
        : '${AuctionCountdownLabel.formatDuration(_remaining)} $suffix';
    return Text(
      text,
      style:
          widget.style ??
          const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
    );
  }
}
