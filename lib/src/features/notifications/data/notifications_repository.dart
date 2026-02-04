import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../domain/notification_model.dart';

/// Response model for paginated notifications
class NotificationsResponse {
  final List<NotificationModel> notifications;
  final int total;
  final int page;
  final int limit;
  final int unreadCount;

  NotificationsResponse({
    required this.notifications,
    required this.total,
    required this.page,
    required this.limit,
    required this.unreadCount,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> notificationsData =
        json['notifications'] ?? json['data'] ?? [];
    return NotificationsResponse(
      notifications: notificationsData
          .map(
            (item) => NotificationModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class NotificationsRepository {
  /// Get paginated notifications for a user
  static Future<NotificationsResponse> getNotifications({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    final result = await DioHelper.getData(
      url: EndPoints.getNotifications(userId),
      query: {'page': page, 'limit': limit},
      token: CachedVariables.token,
    );

    if (result.statusCode == 200) {
      return NotificationsResponse.fromJson(result.data);
    } else {
      String message =
          '${result.data['error'] ?? result.data['message'] ?? 'Failed to fetch notifications'} (code: ${result.statusCode})';
      throw NotificationsException(message, result.statusCode);
    }
  }

  /// Mark a single notification as read
  static Future<bool> markAsRead(int notificationId) async {
    final result = await DioHelper.patchData(
      url: EndPoints.markAsRead(notificationId),
      token: CachedVariables.token,
    );

    if (result.statusCode == 200) {
      return true;
    } else {
      String message =
          '${result.data['error'] ?? result.data['message'] ?? 'Failed to mark notification as read'} (code: ${result.statusCode})';
      throw NotificationsException(message, result.statusCode);
    }
  }

  /// Mark all notifications as read for a user
  static Future<bool> markAllAsRead(int userId) async {
    final result = await DioHelper.patchData(
      url: EndPoints.markAllAsRead(userId),
      token: CachedVariables.token,
    );

    if (result.statusCode == 200) {
      return true;
    } else {
      String message =
          '${result.data['error'] ?? result.data['message'] ?? 'Failed to mark all notifications as read'} (code: ${result.statusCode})';
      throw NotificationsException(message, result.statusCode);
    }
  }

  /// Register device for push notifications
  static Future<bool> registerDevice({
    required int userId,
    required String token,
    required String platform,
  }) async {
    final result = await DioHelper.postData(
      url: EndPoints.registerDevice,
      data: {'user_id': userId, 'token': token, 'platform': platform},
      token: CachedVariables.token,
    );

    if (result.statusCode == 200 || result.statusCode == 201) {
      return true;
    } else {
      String message =
          '${result.data['error'] ?? result.data['message'] ?? 'Failed to register device'} (code: ${result.statusCode})';
      throw NotificationsException(message, result.statusCode);
    }
  }

  /// Unregister device from push notifications
  static Future<bool> unregisterDevice(String deviceToken) async {
    final result = await DioHelper.deleteData(
      url: EndPoints.unregisterDevice,
      data: {'token': deviceToken},
      token: CachedVariables.token,
    );

    if (result.statusCode == 200) {
      return true;
    } else {
      String message =
          '${result.data['error'] ?? result.data['message'] ?? 'Failed to unregister device'} (code: ${result.statusCode})';
      throw NotificationsException(message, result.statusCode);
    }
  }
}

class NotificationsException implements Exception {
  final String message;
  final int? code;

  NotificationsException(this.message, this.code);

  @override
  String toString() {
    return message + (code != null ? ' code: $code' : '');
  }
}

// Providers

/// Provider for the notifications repository
final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository();
});

/// Provider for fetching notifications list
final notificationsListProvider =
    FutureProvider.autoDispose<NotificationsResponse>((ref) async {
      final userId = CachedVariables.userId;
      if (userId == null) {
        throw NotificationsException('User not logged in', 401);
      }
      return NotificationsRepository.getNotifications(userId: userId);
    });

/// Provider for unread notifications count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsListProvider);
  return notificationsAsync.when(
    data: (response) => response.unreadCount,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// StateNotifier for managing notifications state with actions
class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
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
      });
    } catch (e) {
      rethrow;
    }
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider.autoDispose<
      NotificationsNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) => NotificationsNotifier(ref));
