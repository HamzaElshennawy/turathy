import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_sizes.dart';
import '../../domain/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationItem({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead;
    final languageCode = Localizations.localeOf(context).languageCode;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.p16,
          vertical: Sizes.p16, // Increased vertical padding
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            gapW12,
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.formattedTitleFor(languageCode),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  gapH4,
                  Text(
                    notification.localizedBodyFor(languageCode),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  gapH8,
                  Text(
                    notification.timeAgo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
