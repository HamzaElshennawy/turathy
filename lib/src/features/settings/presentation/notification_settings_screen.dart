import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/fcm/notification_prefs.dart';

/// Simple local toggles for push categories (device-side until server prefs exist).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
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
      final v = await NotificationPrefs.storage.read(key: key);
      if (v == null) return def;
      return v == '1';
    }

    final results = await Future.wait([
      read(NotificationPrefs.keyNewAuction),
      read(NotificationPrefs.keyAuctionStarted),
      read(NotificationPrefs.keyCountdown),
      read(NotificationPrefs.keyOutbid),
      read(NotificationPrefs.keyWatch),
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
    await NotificationPrefs.storage.write(key: key, value: value ? '1' : '0');
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
                    _set(NotificationPrefs.keyNewAuction, v);
                  },
                ),
                SwitchListTile(
                  title: Text('auctionStartedNotify'.tr()),
                  value: _auctionStarted,
                  onChanged: (v) {
                    setState(() => _auctionStarted = v);
                    _set(NotificationPrefs.keyAuctionStarted, v);
                  },
                ),
                SwitchListTile(
                  title: Text('countdownNotify'.tr()),
                  value: _countdown,
                  onChanged: (v) {
                    setState(() => _countdown = v);
                    _set(NotificationPrefs.keyCountdown, v);
                  },
                ),
                SwitchListTile(
                  title: Text('outbidNotify'.tr()),
                  value: _outbid,
                  onChanged: (v) {
                    setState(() => _outbid = v);
                    _set(NotificationPrefs.keyOutbid, v);
                  },
                ),
                SwitchListTile(
                  title: Text('watchNotify'.tr()),
                  value: _watchActivity,
                  onChanged: (v) {
                    setState(() => _watchActivity = v);
                    _set(NotificationPrefs.keyWatch, v);
                  },
                ),
              ],
            ),
    );
  }
}
