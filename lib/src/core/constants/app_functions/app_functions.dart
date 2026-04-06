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

  /// Displays a fullscreen interactive image viewer with zoom support.
  static void showImageDialog({
    required BuildContext context,
    required String imageUrl,
    required int id,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        barrierDismissible: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: PhotoView(
            heroAttributes: PhotoViewHeroAttributes(
              tag: id,
              transitionOnUserGestures: true,
            ),
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            initialScale: PhotoViewComputedScale.contained,
          ),
        ),
      ),
    );
  }
}

