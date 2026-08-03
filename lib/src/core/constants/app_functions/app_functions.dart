/// {@category Constants}
///
/// Global utility functions and UI helpers.
/// 
/// This class provides a centralized collection of static methods for:
/// - Responsive design checks ([isMobile]).
/// - Localization shortcuts ([translateText]).
/// - Common UI components (Dialogs, DatePickers, SnackBars).
/// - string/date formatting and platform integrations (URLs).
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:url_launcher/url_launcher.dart';

import '../breakpoints.dart';

/// Static repository of shared logic and common UI interactions.
abstract class AppFunctions {
  /// Simple check for mobile-sized viewports based on [Breakpoint.tablet].
  static bool isMobile({required BuildContext context}) =>
      MediaQuery.of(context).size.width < Breakpoint.tablet;

  /// Shorthand for translating text using [easy_localization].
  static String translateText({required String text, required context}) =>
      text.tr(context: context);

  /// Standardized logging wrapper.
  static void logPrint({required String message}) => log(message);

  /// Displays a localized date picker restricted from 1970 to the current date.
  /// 
  /// Returns a YYYY-MM-DD formatted string or an empty string if canceled.
  static Future<String> showMyDatePicker({
    required BuildContext context,
  }) async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );

    if (result != null) {
      return result.toString().split(" ")[0];
    } else {
      return '';
    }
  }

  /// Displays a standard success alert dialog.
  static Future<dynamic> showSuccessDialogBox({
    required BuildContext context,
    String? title,
    String? description,
    Widget? child,
  }) async => showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description ?? ''),
              if (child != null)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: child,
                ),
            ],
          ),
        ),
      );
    },
  );

  /// Shows a customized floating SnackBar with support for error states.
  static void showSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ??
                  (isError ? Icons.error_outline : Icons.check_circle_outline),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade800
            : (isDarkMode ? Colors.grey.shade800 : Colors.black87),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows a standardized Modal Bottom Sheet with a pull-handle indicator.
  static Future<dynamic> showBottomSheet({
    required BuildContext context,
    required Widget child,
  }) => showModalBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 5,
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );

  /// Helper to join names from a list of objects into a comma-separated string.
  static String getStringFromList({required List item}) =>
      item.map((e) => e.name).join(', ');

  /// Safely attempts to open an external URL in the system browser.
  static Future<void> launchUrl({required String url}) async {
    var uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(url: url);
    } 
  }

  /// Formats an ISO date string to a "Day, Month d" format.
  static String formatDateTimeFromString({required String date}) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('EEEE, MMMM d').format(parsedDate);
  }

  /// Formats an ISO date string to "Day Month d, yyyy" (common in session lists).
  static String formatDateTimeFromStringForSessionDetails({
    required String date,
  }) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('EEEE MMMM d, yyyy').format(parsedDate);
  }

  /// Converts a 24-hour time string ("HH:mm:ss") to 12-hour format ("h:mm AM").
  static String convertTimeFormat(String time24) {
    final format24 = DateFormat('HH:mm:ss');
    final format12 = DateFormat('h:mm a');

    final time = format24.parse(time24);
    return format12.format(time);
  }

  /// Displays a fullscreen interactive image viewer with pinch-to-zoom.
  ///
  /// Pass [images] + [initialIndex] for a swipeable gallery (store / product
  /// details). Single [imageUrl] remains supported for cards and legacy calls.
  static void showImageDialog({
    required BuildContext context,
    String? imageUrl,
    List<String>? images,
    int initialIndex = 0,
    required int id,
  }) {
    final urls = <String>[
      if (images != null && images.isNotEmpty)
        ...images.where((u) => u.trim().isNotEmpty)
      else if (imageUrl != null && imageUrl.trim().isNotEmpty)
        imageUrl.trim(),
    ];
    if (urls.isEmpty) return;

    final start = initialIndex.clamp(0, urls.length - 1);

    Navigator.push(
      context,
      MaterialPageRoute(
        barrierDismissible: true,
        builder: (context) => _ZoomableImageViewer(
          urls: urls,
          initialIndex: start,
          heroTagBase: id,
        ),
      ),
    );
  }
}

/// Fullscreen dark viewer: pinch zoom, pan, and swipe across product images.
class _ZoomableImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final int heroTagBase;

  const _ZoomableImageViewer({
    required this.urls,
    required this.initialIndex,
    required this.heroTagBase,
  });

  @override
  State<_ZoomableImageViewer> createState() => _ZoomableImageViewerState();
}

class _ZoomableImageViewerState extends State<_ZoomableImageViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.urls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: multi
            ? Text(
                '${_index + 1} / ${widget.urls.length}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              )
            : null,
        centerTitle: true,
      ),
      body: multi
          ? PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(widget.urls[index]),
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: '${widget.heroTagBase}_zoom_$index',
                    transitionOnUserGestures: true,
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  initialScale: PhotoViewComputedScale.contained,
                );
              },
            )
          : PhotoView(
              heroAttributes: PhotoViewHeroAttributes(
                tag: widget.heroTagBase,
                transitionOnUserGestures: true,
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              imageProvider: CachedNetworkImageProvider(widget.urls.first),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
              initialScale: PhotoViewComputedScale.contained,
            ),
    );
  }
}

