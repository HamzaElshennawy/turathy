import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Direction-aware slide-to-confirm for one-step live bids.
///
/// In RTL the thumb starts on the right and the user swipes left;
/// drag delta is inverted so the control actually moves on Arabic layouts.
///
/// Thumb width grows with the bid amount so large values (e.g. 1260) stay
/// fully visible instead of collapsing to "سوم …12".
class SwipeToBidBar extends StatefulWidget {
  final String amountText;
  final String hintText;
  final String somLabel;
  final VoidCallback onConfirmed;
  final Color trackColor;
  final Color accentColor;

  const SwipeToBidBar({
    super.key,
    required this.amountText,
    required this.hintText,
    required this.somLabel,
    required this.onConfirmed,
    this.trackColor = const Color(0xFF1A2E22),
    this.accentColor = const Color(0xFF2D4739),
  });

  /// Converts a raw horizontal pointer delta into progress toward confirmation.
  /// Positive result means "more complete" regardless of text direction.
  @visibleForTesting
  static double directedDelta(double dx, TextDirection direction) {
    return direction == TextDirection.rtl ? -dx : dx;
  }

  /// Preferred thumb width for [amountText] / [somLabel] inside [maxTrackWidth].
  @visibleForTesting
  static double thumbWidthFor({
    required String somLabel,
    required String amountText,
    required double maxTrackWidth,
    TextDirection textDirection = TextDirection.rtl,
  }) {
    const minW = 128.0;
    const maxW = 228.0;
    const horizontalPad = 20.0; // 10+10
    const chevronAndGaps = 28.0;
    const rialSlot = 20.0;

    final painter = TextPainter(
      text: TextSpan(
        text: '$somLabel $amountText',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();

    final needed =
        painter.width + horizontalPad + chevronAndGaps + rialSlot;
    final cap = (maxTrackWidth * 0.58).clamp(minW, maxW);
    return needed.clamp(minW, cap);
  }

  @override
  State<SwipeToBidBar> createState() => _SwipeToBidBarState();
}

class _SwipeToBidBarState extends State<SwipeToBidBar>
    with SingleTickerProviderStateMixin {
  static const double _height = 56;
  static const double _confirmThreshold = 0.82;

  double _drag = 0;
  bool _fired = false;
  Timer? _resetTimer;
  late final AnimationController _snapBack;

  @override
  void initState() {
    super.initState();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (!mounted || _fired) return;
        setState(() {
          _drag = _drag * (1 - Curves.easeOutCubic.transform(_snapBack.value));
          if (_snapBack.isCompleted) _drag = 0;
        });
      });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _snapBack.dispose();
    super.dispose();
  }

  void _resetAnimated() {
    if (_drag <= 0) {
      setState(() => _fired = false);
      return;
    }
    _snapBack.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _drag = 0;
        _fired = false;
      });
    });
  }

  void _hardReset() {
    _snapBack.stop();
    _resetTimer?.cancel();
    setState(() {
      _drag = 0;
      _fired = false;
    });
  }

  void _applyDelta(double dx, double maxDrag) {
    if (_fired || maxDrag <= 0) return;
    final direction = Directionality.of(context);
    final next = (_drag + SwipeToBidBar.directedDelta(dx, direction))
        .clamp(0.0, maxDrag);
    setState(() => _drag = next);

    final progress = next / maxDrag;
    if (!_fired && progress >= _confirmThreshold) {
      _fired = true;
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {
        // Haptics unavailable in some test/desktop hosts.
      }
      widget.onConfirmed();
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(milliseconds: 420), () {
        if (mounted) _hardReset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final textDirection = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbWidth = SwipeToBidBar.thumbWidthFor(
          somLabel: widget.somLabel,
          amountText: widget.amountText,
          maxTrackWidth: constraints.maxWidth,
          textDirection: textDirection,
        );
        final maxDrag =
            (constraints.maxWidth - thumbWidth - 8).clamp(0.0, 600.0);
        final progress =
            maxDrag == 0 ? 0.0 : (_drag / maxDrag).clamp(0.0, 1.0);
        final thumbOffset = isRtl ? -_drag : _drag;

        return Semantics(
          button: true,
          label: '${widget.hintText} ${widget.amountText}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) {
              _snapBack.stop();
            },
            onHorizontalDragUpdate: (details) {
              _applyDelta(details.delta.dx, maxDrag);
            },
            onHorizontalDragEnd: (_) {
              if (!_fired) _resetAnimated();
            },
            onHorizontalDragCancel: () {
              if (!_fired) _resetAnimated();
            },
            child: SizedBox(
              height: _height,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.trackColor,
                  borderRadius: BorderRadius.circular(_height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_height / 2),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: isRtl
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (thumbWidth + _drag) /
                              constraints.maxWidth.clamp(1, 9999),
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: isRtl
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                end: isRtl
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                colors: [
                                  widget.accentColor,
                                  widget.accentColor.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      Opacity(
                        opacity: (1 - progress * 1.35).clamp(0.0, 1.0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: thumbWidth + 8,
                            end: 16,
                          ),
                          child: Text(
                            widget.hintText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Transform.translate(
                          offset: Offset(thumbOffset, 0),
                          child: Container(
                            width: thumbWidth,
                            height: _height - 8,
                            margin: const EdgeInsetsDirectional.only(
                              start: 4,
                              end: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.accentColor,
                              borderRadius:
                                  BorderRadius.circular((_height - 8) / 2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isRtl
                                      ? Icons.keyboard_double_arrow_left_rounded
                                      : Icons
                                          .keyboard_double_arrow_right_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${widget.somLabel} ${widget.amountText}',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  '﷼',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
