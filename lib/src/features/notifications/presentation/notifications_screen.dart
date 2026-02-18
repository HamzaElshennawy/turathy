import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turathy/src/core/helper/fcm/fcm_service.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

import 'package:turathy/src/features/notifications/domain/notification_model.dart';
import 'package:turathy/src/features/notifications/presentation/notifications_controller.dart';
import 'package:turathy/src/features/notifications/presentation/widgets/notification_item_widget.dart';
import 'package:turathy/src/routing/rout_constants.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppStrings.notifications.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () {
              FCMService().showTestNotification();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                try {
                  await ref
                      .read(notificationsNotifierProvider.notifier)
                      .markAllAsRead();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.allNotificationsMarkedRead.tr(),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${AppStrings.failedToMarkNotifications.tr()}: $e',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    const Icon(Icons.done_all, size: 20),
                    const SizedBox(width: 8),
                    Text(AppStrings.markAllAsRead.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: notificationsAsync.when(
        data: (notifications) =>
            _buildNotificationsList(context, ref, notifications),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List<NotificationModel> notifications,
  ) {
    if (notifications.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationsNotifierProvider.notifier).refresh();
      },
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationItem(
            notification: notification,
            onTap: () async {
              if (!notification.isRead) {
                try {
                  await ref
                      .read(notificationsNotifierProvider.notifier)
                      .markAsRead(notification.id);
                } catch (e) {
                  // Silently fail for mark as read
                }
              }
              _handleNotificationTap(context, notification);
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    // Check if notification has data for navigation
    final data = notification.data;
    final type = notification.type;

    if (type == 'AUCTION_STARTED' ||
        type == 'NEW_BID' ||
        type == 'OUTBID' ||
        type == 'AUCTION_WON' ||
        type == 'AUCTION_ENDING_SOON') {
      // Try to get auction ID from data
      String? auctionId;
      if (data != null && data.containsKey('auction_id')) {
        auctionId = data['auction_id'].toString();
      } else if (data != null && data.containsKey('id')) {
        auctionId = data['id'].toString();
      }

      if (auctionId != null) {
        context.pushNamed(
          RouteConstants.liveAuction,
          pathParameters: {'id': auctionId},
        );
      }
    } else if (type == 'ORDER_STATUS') {
      context.pushNamed(RouteConstants.orders);
    } else if (type == 'BROADCAST') {
      _showNotificationDialog(context, notification);
    } else if (data != null) {
      // Fallback checking data directly if type doesn't match
      if (data.containsKey('auction_id')) {
        context.pushNamed(
          RouteConstants.liveAuction,
          pathParameters: {'id': data['auction_id'].toString()},
        );
      } else if (data.containsKey('order_id')) {
        context.pushNamed(RouteConstants.orders);
      } else {
        _showNotificationDialog(context, notification);
      }
    } else {
      _showNotificationDialog(context, notification);
    }
  }

  void _showNotificationDialog(
    BuildContext context,
    NotificationModel notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(child: Text(notification.body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.ok.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notificationsNotifierProvider.notifier).refresh();
      },
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.noNotifications.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.notificationsWillAppearHere.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    // Check if error is related to authentication (401)
    final isAuthError =
        error.toString().contains('401') ||
        error.toString().toLowerCase().contains('unauthorized') ||
        error.toString().contains('User not logged in');

    if (isAuthError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.pleaseSignInOrCreateAccount.tr(),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.push(RouteConstants.signIn);
                },
                child: Text(AppStrings.signIn.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              AppStrings.errorLoadingNotifications.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(notificationsNotifierProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.retry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
