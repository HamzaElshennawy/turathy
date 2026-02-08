import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/core/helper/fcm/fcm_service.dart';
import 'package:turathy/src/features/notifications/data/notifications_repository.dart';
import 'package:turathy/src/features/notifications/domain/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// StateNotifier for managing notifications state with actions
class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref ref;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  NotificationsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadNotifications();
    _listenToMessages();
  }

  void _listenToMessages() {
    _messageSubscription = fcmService.onMessage.listen((message) async {
      print('FCM Message received in controller. Triggering refresh...');
      // Small delay to ensure DB is updated
      await Future.delayed(const Duration(seconds: 1));
      // Refresh notifications list when a new message arrives
      refresh();
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    // Only set loading state if we don't have data yet (initial load)
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      final userId = CachedVariables.userId;
      if (userId == null) {
        state = AsyncValue.error(
          NotificationsException('User not logged in', 401),
          StackTrace.current,
        );
        return;
      }
      final response = await NotificationsRepository.getNotifications(
        userId: userId,
      );
      // Update unread count
      ref.read(unreadCountProvider.notifier).state = response.unreadCount;
      state = AsyncValue.data(response.notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await NotificationsRepository.markAsRead(notificationId);
      // Update local state
      state.whenData((notifications) {
        final updated = notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        state = AsyncValue.data(updated);

        // Decrement unread count
        final currentCount = ref.read(unreadCountProvider);
        if (currentCount > 0) {
          ref.read(unreadCountProvider.notifier).state = currentCount - 1;
        }
      });
    } catch (e) {
      // Silently fail but could show error toast
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final userId = CachedVariables.userId;
      if (userId == null) return;

      await NotificationsRepository.markAllAsRead(userId);
      // Update local state
      state.whenData((notifications) {
        final updated = notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        state = AsyncValue.data(updated);

        // Reset unread count
        ref.read(unreadCountProvider.notifier).state = 0;
      });
    } catch (e) {
      rethrow;
    }
  }
}

final unreadCountProvider = StateProvider<int>((ref) => 0);

final notificationsNotifierProvider =
    StateNotifierProvider<
      NotificationsNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) => NotificationsNotifier(ref));
