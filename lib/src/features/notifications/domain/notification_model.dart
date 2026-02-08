import 'package:easy_localization/easy_localization.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

/// Model representing a notification from the backend API
class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          body == other.body &&
          type == other.type &&
          isRead == other.isRead &&
          createdAt == other.createdAt);

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      body.hashCode ^
      type.hashCode ^
      isRead.hashCode ^
      createdAt.hashCode;

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Format the createdAt date as a relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 1) {
      return AppStrings.daysAgo.tr(args: [difference.inDays.toString()]);
    } else if (difference.inDays == 1) {
      return AppStrings.yesterday.tr();
    } else if (difference.inHours >= 1) {
      return AppStrings.hoursAgo.tr(args: [difference.inHours.toString()]);
    } else if (difference.inMinutes >= 1) {
      return AppStrings.minutesAgo.tr(args: [difference.inMinutes.toString()]);
    } else {
      return AppStrings.justNow.tr();
    }
  }

  /// Get formatted title based on notification type or return raw title
  String get formattedTitle {
    if (type == null) return title;

    switch (type) {
      case 'AUCTION_STARTED':
        return AppStrings.notificationAuctionStarted.tr();
      case 'NEW_BID':
        return AppStrings.notificationNewBid.tr();
      case 'OUTBID':
        return AppStrings.notificationOutbid.tr();
      case 'AUCTION_WON':
        return AppStrings.notificationAuctionWon.tr();
      case 'AUCTION_ENDING_SOON':
        return AppStrings.notificationAuctionEndingSoon.tr();
      case 'ORDER_STATUS':
        return AppStrings.notificationOrderStatus.tr();
      default:
        return title;
    }
  }
}
