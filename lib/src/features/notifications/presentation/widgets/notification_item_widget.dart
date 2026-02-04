import 'package:flutter/material.dart';
import 'package:turathi/src/core/constants/app_sizes.dart';
import '../../domain/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationItem({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.p16,
          vertical: Sizes.p12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsetsDirectional.only(end: 8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  notification.timeAgo,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            gapH8,
            Padding(
              padding: EdgeInsetsDirectional.only(start: isRead ? 0 : 16),
              child: Text(
                notification.body,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            gapH12,
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}
