import 'dart:async';

import 'package:flutter/material.dart';

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
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else if (duration.inMinutes > 0) {
      return '$minutes:$seconds';
    } else {
      return '${duration.inSeconds} sec';
    }
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
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final next = _computeRemaining();
        setState(() => _remaining = next);
        if (next <= Duration.zero) {
          _timer?.cancel();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AuctionCountdownLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _timer?.cancel();
      _remaining = _computeRemaining();
      if (_remaining > Duration.zero) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          final next = _computeRemaining();
          setState(() => _remaining = next);
          if (next <= Duration.zero) {
            _timer?.cancel();
          }
        });
      }
    }
  }

  Duration _computeRemaining() {
    final difference = widget.target.difference(DateTime.now());
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
