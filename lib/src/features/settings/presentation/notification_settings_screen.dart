import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

/// Simple local toggles for push categories (device-side until server prefs exist).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _storage = FlutterSecureStorage();

  bool _newAuction = true;
  bool _auctionStarted = true;
  bool _countdown = true;
  bool _outbid = true;
  bool _watchActivity = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Future<bool> read(String key, {bool def = true}) async {
      final v = await _storage.read(key: key);
      if (v == null) return def;
      return v == '1';
    }

    final results = await Future.wait([
      read('notif_new_auction'),
      read('notif_auction_started'),
      read('notif_countdown'),
      read('notif_outbid'),
      read('notif_watch'),
    ]);
    if (!mounted) return;
    setState(() {
      _newAuction = results[0];
      _auctionStarted = results[1];
      _countdown = results[2];
      _outbid = results[3];
      _watchActivity = results[4];
      _loading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    await _storage.write(key: key, value: value ? '1' : '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.notificationSettings.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text('newAuctionNotify'.tr()),
                  value: _newAuction,
                  onChanged: (v) {
                    setState(() => _newAuction = v);
                    _set('notif_new_auction', v);
                  },
                ),
                SwitchListTile(
                  title: Text('auctionStartedNotify'.tr()),
                  value: _auctionStarted,
                  onChanged: (v) {
                    setState(() => _auctionStarted = v);
                    _set('notif_auction_started', v);
                  },
                ),
                SwitchListTile(
                  title: Text('countdownNotify'.tr()),
                  value: _countdown,
                  onChanged: (v) {
                    setState(() => _countdown = v);
                    _set('notif_countdown', v);
                  },
                ),
                SwitchListTile(
                  title: Text('outbidNotify'.tr()),
                  value: _outbid,
                  onChanged: (v) {
                    setState(() => _outbid = v);
                    _set('notif_outbid', v);
                  },
                ),
                SwitchListTile(
                  title: Text('watchNotify'.tr()),
                  value: _watchActivity,
                  onChanged: (v) {
                    setState(() => _watchActivity = v);
                    _set('notif_watch', v);
                  },
                ),
              ],
            ),
    );
  }
}
