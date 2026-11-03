import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/time/server_clock.dart';
import 'package:turathy/src/core/time/server_countdown.dart';

/// Three-minute preparation clock. The only words are the localized label.
class AuctionPrepBanner extends StatefulWidget {
  const AuctionPrepBanner({
    super.key,
    required this.serverNow,
    required this.prepSeconds,
    this.startsAt,
  });

  final DateTime serverNow;
  final int prepSeconds;
  final DateTime? startsAt;

  @override
  State<AuctionPrepBanner> createState() => _AuctionPrepBannerState();
}

class _AuctionPrepBannerState extends State<AuctionPrepBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _notePassive();
    _arm();
  }

  @override
  void didUpdateWidget(AuctionPrepBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverNow != widget.serverNow || oldWidget.startsAt != widget.startsAt) {
      _notePassive();
      _arm();
    }
  }

  void _notePassive() {
    serverClock.notePassive(
      widget.serverNow.millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _arm() {
    _ticker?.cancel();
    final remainMs = _remainingMs;
    if (remainMs <= 0) return;
    _ticker = armServerCountdown(
      remainMs: remainMs,
      onTick: () {
        if (!mounted) return;
        setState(_arm);
      },
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _remainingMs {
    final startsAt = widget.startsAt;
    final now = serverClock.nowDate();
    final cap = widget.prepSeconds * 1000;
    if (startsAt != null) {
      final left = startsAt.difference(now).inMilliseconds;
      if (left < 0) return 0;
      if (left > cap) return cap;
      return left;
    }
    final elapsed = now.difference(widget.serverNow).inMilliseconds;
    final left = cap - elapsed;
    if (left < 0) return 0;
    if (left > cap) return cap;
    return left;
  }

  int get _remainingSeconds => displaySeconds(_remainingMs);

  @override
  Widget build(BuildContext context) {
    final remaining = _remainingSeconds;
    if (remaining <= 0) return const SizedBox.shrink();
    final minutes = (remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (remaining % 60).toString().padLeft(2, '0');
    final label = 'auctionPrepLabel'.tr();
    return Semantics(
      liveRegion: true,
      label: '$label $minutes:$seconds',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8A6A32)),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '$minutes:$seconds',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
