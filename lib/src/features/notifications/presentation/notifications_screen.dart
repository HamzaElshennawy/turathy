import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/analytics/analytics_service.dart';
import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:go_router/go_router.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/constants/app_functions/app_functions.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:turathy/src/features/notifications/domain/notification_model.dart';
import 'package:turathy/src/features/notifications/presentation/notifications_controller.dart';
import 'package:turathy/src/features/notifications/presentation/widgets/notification_item_widget.dart';
import 'package:turathy/src/routing/rout_constants.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'notifications_screen');
  }

  @override
  Widget build(BuildContext context) {
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
          Theme(
            data: Theme.of(context).copyWith(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              elevation: 8,
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).cardColor,
              onSelected: (value) async {
                if (value == 'mark_all_read') {
                  try {
                    await ref
                        .read(notificationsNotifierProvider.notifier)
                        .markAllAsRead();
                    if (context.mounted) {
                      AppFunctions.showSnackBar(
                        context: context,
                        message: AppStrings.allNotificationsMarkedRead.tr(),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppFunctions.showSnackBar(
                        context: context,
                        message:
                            '${AppStrings.failedToMarkNotifications.tr()}: $e',
                        isError: true,
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.markAllAsRead.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    debugPrint('Notification tapped: ${notification.title}');
    debugPrint('Notification type: ${notification.type}');
    debugPrint('Notification data: ${notification.data}');

    // Check if notification has data for navigation
    final data = notification.data;
    final type = notification.type;

    if (type == 'AUCTION_STARTED' ||
        type == 'AUCTION_WON' ||
        type == 'AUCTION_ENDING_SOON') {
      // These types definitively mean the auction is live
      String? auctionId;
      if (data != null && data.containsKey('auction_id')) {
        auctionId = data['auction_id'].toString();
      } else if (data != null && data.containsKey('id')) {
        auctionId = data['id'].toString();
      } else if (data != null && data.containsKey('auctionId')) {
        auctionId = data['auctionId'].toString();
      }

      debugPrint('Extracted auctionId: $auctionId');

      if (auctionId != null) {
        context.pushNamed(
          RouteConstants.liveAuction,
          pathParameters: {'id': auctionId},
        );
      }
    } else if (type == 'OUTBID' || type == 'NEW_BID') {
      // Route to adaptive auction details — shows AuctionScreen
      // (pre-auction) or LiveAuctionScreen (live) based on auction state
      String? auctionId;
      if (data != null && data.containsKey('auction_id')) {
        auctionId = data['auction_id'].toString();
      } else if (data != null && data.containsKey('id')) {
        auctionId = data['id'].toString();
      } else if (data != null && data.containsKey('auctionId')) {
        auctionId = data['auctionId'].toString();
      }

      debugPrint('Extracted auctionId: $auctionId');

      if (auctionId != null) {
        context.pushNamed(
          RouteConstants.auctionDetails,
          pathParameters: {'id': auctionId},
        );
      }
    } else if (type == 'ORDER_STATUS' || type == 'PAYMENT_APPROVED') {
      final orderId = data?['orderid'] ?? data?['orderId'];
      if (orderId != null) {
        context.pushNamed(
          RouteConstants.orderDetails,
          pathParameters: {'id': orderId.toString()},
        );
      } else {
        context.pushNamed(RouteConstants.orders);
      }
    } else if (type == 'BROADCAST') {
      _showNotificationDialog(context, notification);
    } else if (data != null) {
      // Fallback checking data directly if type doesn't match
      if (data.containsKey('auction_id')) {
        context.pushNamed(
          RouteConstants.liveAuction,
          pathParameters: {'id': data['auction_id'].toString()},
        );
      } else if (data.containsKey('auctionId')) {
        context.pushNamed(
          RouteConstants.liveAuction,
          pathParameters: {'id': data['auctionId'].toString()},
        );
      } else if (data.containsKey('order_id') || data.containsKey('orderId')) {
        final orderId = data['order_id'] ?? data['orderId'];
        context.pushNamed(
          RouteConstants.orderDetails,
          pathParameters: {'id': orderId.toString()},
        );
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
    final theme = Theme.of(context);
    final languageCode = context.locale.languageCode;
    final imageUrl = _resolveNotificationImageUrl(
      notification.data?['imageUrl']?.toString(),
    );
    final externalUrl = notification.data?['url']?.toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.18,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _notificationIcon(notification.type),
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          notification.formattedTitleFor(languageCode),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              notification.timeAgo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text(
                      notification.localizedBodyFor(languageCode),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (externalUrl != null && externalUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                externalUrl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Row(
                      children: [
                        if (externalUrl != null && externalUrl.isNotEmpty) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final uri = Uri.tryParse(externalUrl);
                                if (uri != null) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: Text(AppStrings.openLink.tr()),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppStrings.ok.tr()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _notificationIcon(String? type) {
    switch (type) {
      case 'PROMOTIONAL':
        return Icons.campaign_rounded;
      case 'BROADCAST':
        return Icons.notifications_active_rounded;
      case 'PAYMENT_APPROVED':
      case 'ORDER_STATUS':
        return Icons.receipt_long_rounded;
      default:
        return Icons.mark_email_unread_rounded;
    }
  }

  String? _resolveNotificationImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final normalizedPath = imageUrl.startsWith('/')
        ? imageUrl.substring(1)
        : imageUrl;
    return '${EndPoints.baseUrl}$normalizedPath';
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

