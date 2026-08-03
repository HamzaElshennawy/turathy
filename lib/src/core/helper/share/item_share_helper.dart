import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Builds public share links and opens system / WhatsApp / SMS share flows.
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

  static String _message({
    required String title,
    required String url,
  }) =>
      '$title\n$url';

  static Future<void> shareSystem({
    required String title,
    required String url,
  }) async {
    await Share.share(_message(title: title, url: url), subject: title);
  }

  static Future<void> shareWhatsApp({
    required String title,
    required String url,
  }) async {
    final text = Uri.encodeComponent(_message(title: title, url: url));
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await shareSystem(title: title, url: url);
    }
  }

  static Future<void> shareSms({
    required String title,
    required String url,
  }) async {
    final body = Uri.encodeComponent(_message(title: title, url: url));
    final uri = Uri.parse('sms:?body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await shareSystem(title: title, url: url);
    }
  }

  static Future<void> copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
  }
}
