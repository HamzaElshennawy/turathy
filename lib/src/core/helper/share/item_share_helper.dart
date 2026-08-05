import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of trying to open a dedicated share target (WhatsApp / SMS).
enum ShareLaunchResult {
  /// Native app intent opened successfully.
  openedApp,

  /// Dedicated app missing/unavailable — system share sheet used instead.
  fellBackToSystem,
}

/// Builds public share links and opens system / WhatsApp / SMS share flows.
///
/// WhatsApp uses the `whatsapp://` app scheme (never browser `wa.me`) so a
/// missing app does not dump the user on an error web page.
class ItemShareHelper {
  static const String storefrontBase = 'https://alturathaljmeel.com.sa';

  static String auctionLotUrl({
    required int auctionId,
    int? lotNumber,
    int? productId,
  }) {
    final params = <String>[];
    if (lotNumber != null) params.add('lot=$lotNumber');
    if (productId != null) params.add('product=$productId');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return '$storefrontBase/auctions/$auctionId$query';
  }

  static String productUrl({required int productId}) =>
      '$storefrontBase/products/$productId';

  static String shareMessage({
    required String title,
    required String url,
  }) =>
      '$title\n$url';

  /// Native WhatsApp deep link (opens the installed app, not a browser).
  @visibleForTesting
  static Uri whatsappAppUri(String message) => Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(message)}',
      );

  /// Native SMS composer deep link.
  @visibleForTesting
  static Uri smsAppUri(String message) =>
      Uri.parse('sms:?body=${Uri.encodeComponent(message)}');

  static Future<void> shareSystem({
    required String title,
    required String url,
  }) async {
    await Share.share(
      shareMessage(title: title, url: url),
      subject: title,
    );
  }

  static Future<ShareLaunchResult> shareWhatsApp({
    required String title,
    required String url,
  }) async {
    final message = shareMessage(title: title, url: url);
    final opened = await _tryLaunchExternal(whatsappAppUri(message));
    if (opened) return ShareLaunchResult.openedApp;

    await shareSystem(title: title, url: url);
    return ShareLaunchResult.fellBackToSystem;
  }

  static Future<ShareLaunchResult> shareSms({
    required String title,
    required String url,
  }) async {
    final message = shareMessage(title: title, url: url);
    final opened = await _tryLaunchExternal(smsAppUri(message));
    if (opened) return ShareLaunchResult.openedApp;

    // Some OEMs only resolve smsto:
    final openedSmsto = await _tryLaunchExternal(
      Uri.parse('smsto:?body=${Uri.encodeComponent(message)}'),
    );
    if (openedSmsto) return ShareLaunchResult.openedApp;

    await shareSystem(title: title, url: url);
    return ShareLaunchResult.fellBackToSystem;
  }

  static Future<void> copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }

  static Future<bool> _tryLaunchExternal(Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
