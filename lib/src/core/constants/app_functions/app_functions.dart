import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../breakpoints.dart';

abstract class AppFunctions {
  static bool isMobile({required BuildContext context}) =>
      MediaQuery.of(context).size.width < Breakpoint.tablet;

  static String translateText({required String text, required context}) =>
      text.tr(context: context);

  static void logPrint({required String message}) => log(message);

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
              // Image.asset(AppIcons.success),
              Text(title ?? ''),
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

  //snack bar
  static void showSnackBar({
    required BuildContext context,
    required String message,
  }) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(message),
      ),
    ),
  );

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

  static String getStringFromList({required List item}) =>
      item.map((e) => e.name).join(', ');

  static Future<void> launchUrl({required String url}) async {
    var uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(url: url);
    } else {
      // can't launch url
    }
  }

  static String formatDateTimeFromString({required String date}) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('EEEE, MMMM d').format(parsedDate);
  }

  // format date to be like this "Friday August 11, 2023"
  static String formatDateTimeFromStringForSessionDetails({
    required String date,
  }) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('EEEE MMMM d, yyyy').format(parsedDate);
  }

  static String convertTimeFormat(String time24) {
    final format24 = DateFormat('HH:mm:ss');
    final format12 = DateFormat('h:mm a');

    final time = format24.parse(time24);
    return format12.format(time);
  }

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
          ),
        ),
      ),
    );
  }
}
