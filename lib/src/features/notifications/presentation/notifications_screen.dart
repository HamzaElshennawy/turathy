import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/notifications/presentation/widgets/notification_item_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifications = [
      {
        'title': 'تم بدأ المزاد',
        'subTitle': 'المزاد علي قطعه اثرية مصرية قديمة',
        'time': 'منذ 4 دقائق',
      },
      {
        'title': 'سيبدأ المزاد القادم بعد 10 دقائق',
        'subTitle': 'المزاد علي قطعه اثرية مصرية قديمة',
        'time': 'منذ 14 دقائق',
      },
      {
        'title': 'تم انهاء المزاد',
        'subTitle': 'تم انهاء المزاد من قبل احمد علي ب 500\$',
        'time': 'منذ امس',
      },
      {
        'title': 'تم بدأ المزاد',
        'subTitle': 'المزاد علي قطعه اثرية مصرية قديمة',
        'time': 'منذ 4 دقائق',
      },
      {
        'title': 'تم بدأ المزاد',
        'subTitle': 'المزاد علي قطعه اثرية مصرية قديمة',
        'time': 'منذ 4 دقائق',
      },
      {
        'title': 'تم بدأ المزاد',
        'subTitle': 'المزاد علي قطعه اثرية مصرية قديمة',
        'time': 'منذ 4 دقائق',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppStrings.notifications.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              child: const Icon(Icons.notifications_none, color: Colors.black),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];
          return NotificationItem(
            title: item['title']!,
            subTitle: item['subTitle']!,
            time: item['time']!,
          );
        },
      ),
    );
  }
}
