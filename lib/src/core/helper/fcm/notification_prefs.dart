import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-side notification category prefs (More → Notification settings).
///
/// Keys match [NotificationSettingsScreen]. Used by FCM to suppress
/// foreground heads-up when the user disabled a category.
class NotificationPrefs {
  NotificationPrefs._();

  static const storage = FlutterSecureStorage();

  static const keyNewAuction = 'notif_new_auction';
  static const keyAuctionStarted = 'notif_auction_started';
  static const keyCountdown = 'notif_countdown';
  static const keyOutbid = 'notif_outbid';
  static const keyWatch = 'notif_watch';

  static Future<bool> _read(String key, {bool def = true}) async {
    final v = await storage.read(key: key);
    if (v == null) return def;
    return v == '1';
  }

  /// Maps backend [NotificationType] / data.type to a local toggle.
  /// Returns false when the user disabled that category.
  static Future<bool> shouldShowType(String? type) async {
    final t = (type ?? '').trim().toUpperCase();
    if (t.isEmpty) return true;

    switch (t) {
      case 'PROMOTIONAL':
      case 'BROADCAST':
        return _read(keyNewAuction);
      case 'AUCTION_STARTED':
        return _read(keyAuctionStarted);
      case 'AUCTION_ENDING_SOON':
        return _read(keyCountdown);
      case 'OUTBID':
        return _read(keyOutbid);
      case 'NEW_BID':
        // Lot-watch activity uses NEW_BID on the server.
        return _read(keyWatch);
      default:
        return true;
    }
  }

  /// Prefer explicit data.type, then nested payload fields.
  static String? resolveType(Map<String, dynamic> data) {
    final direct = data['type']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final nested = data['notificationType']?.toString();
    if (nested != null && nested.isNotEmpty) return nested;
    return null;
  }
}
