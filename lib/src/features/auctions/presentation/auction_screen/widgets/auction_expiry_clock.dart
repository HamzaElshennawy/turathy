import 'dart:async';

import 'package:flutter/material.dart';

/// Lot remaining-time pill. Owns its 1s ticker so bidding controls do not rebuild.
class AuctionExpiryClock extends StatefulWidget {
  final DateTime? expiry;
  final num durationThreshold;
  final bool isAuctionEnded;
  final VoidCallback? onExpired;

  const AuctionExpiryClock({
    super.key,
    required this.expiry,
    required this.durationThreshold,
    this.isAuctionEnded = false,
    this.onExpired,
  });

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
  State<AuctionExpiryClock> createState() => _AuctionExpiryClockState();
}

class _AuctionExpiryClockState extends State<AuctionExpiryClock> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _didNotifyExpired = false;

  @override
  void initState() {
    super.initState();
    _remainingTime = _computeRemaining();
    _startTimer();
    if (_remainingTime <= Duration.zero) {
      _notifyExpired();
    }
  }

  @override
  void didUpdateWidget(covariant AuctionExpiryClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final expiryChanged = oldWidget.expiry != widget.expiry;
    if (expiryChanged) {
      _didNotifyExpired = false;
      _remainingTime = _computeRemaining();
      _startTimer();
      if (_remainingTime <= Duration.zero) {
        _notifyExpired();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.expiry == null) return;
    if (_remainingTime <= Duration.zero) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _computeRemaining();
      setState(() => _remainingTime = next);
      if (next <= Duration.zero) {
        _timer?.cancel();
        _notifyExpired();
      }
    });
  }

  Duration _computeRemaining() {
    final expiry = widget.expiry;
    if (expiry == null) return Duration.zero;
    final difference = expiry.difference(DateTime.now());
    return difference.isNegative ? Duration.zero : difference;
  }

  void _notifyExpired() {
    if (_didNotifyExpired) return;
    _didNotifyExpired = true;
    final callback = widget.onExpired;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final num durationThreshold = widget.durationThreshold;
    final bool showProgressBar =
        _remainingTime.inSeconds <= durationThreshold &&
        _remainingTime.inSeconds > 0;
    final double progress = showProgressBar
        ? _remainingTime.inSeconds / durationThreshold.toDouble()
        : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          if (showProgressBar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: MediaQuery.of(context).size.width * progress,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _remainingTime.inSeconds <= 10
                      ? [
                          const Color(0xFFD32F2F).withAlpha(180),
                          const Color(0xFFFF5252).withAlpha(150),
                        ]
                      : [
                          const Color(0xFF2D4739).withAlpha(180),
                          const Color(0xFF4CAF50).withAlpha(150),
                        ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                AuctionExpiryClock.formatDuration(_remainingTime),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: showProgressBar
                      ? Colors.black
                      : (widget.isAuctionEnded ? Colors.red : Colors.black87),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
