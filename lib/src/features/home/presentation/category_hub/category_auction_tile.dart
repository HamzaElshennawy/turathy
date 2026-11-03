import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings/app_strings.dart';
import '../../../../core/time/server_clock.dart';
import '../../../auctions/domain/auction_model.dart';
import '../../../auctions/presentation/auction_screen/auction_screen.dart';

/// First usable cover: the auction photo, then the gallery. Already-absolute
/// URLs stay as they are so a relative path is not prefixed twice.
String resolveAuctionCoverUrl({
  String? imageUrl,
  Iterable<String> gallery = const [],
}) {
  final primary = imageUrl?.trim() ?? '';
  if (primary.isNotEmpty) return primary;
  for (final image in gallery) {
    final value = image.trim();
    if (value.isNotEmpty) return value;
  }
  return '';
}

/// `HH:MM:SS` when the wait is at least an hour, otherwise `MM:SS`.
String formatAuctionCountdown(Duration duration) {
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    return '${duration.inHours}:$minutes:$seconds';
  }
  if (duration.inMinutes > 0) {
    return '$minutes:$seconds';
  }
  return '${duration.inSeconds} sec';
}

/// Auction preview: full image, title, and the live countdown the customer needs.
class CategoryAuctionTile extends StatefulWidget {
  const CategoryAuctionTile({super.key, required this.auction});

  final AuctionModel auction;

  @override
  State<CategoryAuctionTile> createState() => _CategoryAuctionTileState();
}

class _CategoryAuctionTileState extends State<CategoryAuctionTile> {
  Timer? _timer;
  final ValueNotifier<Duration> _untilLive = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _untilPrep = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(CategoryAuctionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _untilLive.dispose();
    _untilPrep.dispose();
    super.dispose();
  }

  void _tick() {
    final now = serverClock.nowDate();
    final liveStart = widget.auction.liveStartDate;
    final prepStart = widget.auction.startDate;
    _untilLive.value = liveStart != null && liveStart.isAfter(now)
        ? liveStart.difference(now)
        : Duration.zero;
    _untilPrep.value = prepStart != null && prepStart.isAfter(now)
        ? prepStart.difference(now)
        : Duration.zero;
  }

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuctionScreen(widget.auction)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.auction.localizedTitle(context.locale.languageCode);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _AuctionCover(
                imageUrl: resolveAuctionCoverUrl(
                  imageUrl: widget.auction.imageUrl,
                  gallery: widget.auction.auctionImages ?? const [],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title.isEmpty ? AppStrings.auctions.tr() : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  gapH4,
                  ValueListenableBuilder<Duration>(
                    valueListenable: _untilLive,
                    builder: (context, untilLive, _) {
                      return ValueListenableBuilder<Duration>(
                        valueListenable: _untilPrep,
                        builder: (context, untilPrep, _) {
                          return _TimingLines(
                            auction: widget.auction,
                            untilLive: untilLive,
                            untilPrep: untilPrep,
                          );
                        },
                      );
                    },
                  ),
                  gapH8,
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _open(context),
                      child: Text(
                        AppStrings.requestAccess.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingLines extends StatelessWidget {
  const _TimingLines({
    required this.auction,
    required this.untilLive,
    required this.untilPrep,
  });

  final AuctionModel auction;
  final Duration untilLive;
  final Duration untilPrep;

  @override
  Widget build(BuildContext context) {
    final now = serverClock.nowDate();
    final start = auction.startDate;
    final ended = auction.isExpired == true ||
        (auction.expiryDate != null && !auction.expiryDate!.isAfter(now));

    if (start == null && auction.liveStartDate == null) {
      return const SizedBox.shrink();
    }
    if (ended) {
      return Text(
        AppStrings.endedOn.tr(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
      );
    }
    if (untilPrep > Duration.zero) {
      return Text(
        '${AppStrings.remainingTime.tr()} ${AppStrings.untilPreAuction.tr()}: ${formatAuctionCountdown(untilPrep)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B5E20),
        ),
      );
    }

    final liveStillAhead = untilLive > Duration.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.preAuctionStarted.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        gapH4,
        Text(
          liveStillAhead
              ? '${AppStrings.remainingTime.tr()} ${AppStrings.untilLive.tr()}: ${formatAuctionCountdown(untilLive)}'
              : AppStrings.joinNow.tr(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: liveStillAhead ? const Color(0xFFD32F2F) : const Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }
}

/// Full auction photo, decoded at card size so a large scan cannot freeze the UI.
class _AuctionCover extends StatelessWidget {
  const _AuctionCover({required this.imageUrl});

  final String imageUrl;

  static const Color _backdrop = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const ColoredBox(
        color: _backdrop,
        child: Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
      );
    }

    return ColoredBox(
      color: _backdrop,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        memCacheHeight: 720,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey),
        ),
      ),
    );
  }
}
