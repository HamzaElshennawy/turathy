import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';

/// Model representing a notification from the backend API
class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String? titleAr;
  final String? titleEn;
  final String? bodyAr;
  final String? bodyEn;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.titleAr,
    this.titleEn,
    this.bodyAr,
    this.bodyEn,
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
          titleAr == other.titleAr &&
          titleEn == other.titleEn &&
          bodyAr == other.bodyAr &&
          bodyEn == other.bodyEn &&
          type == other.type &&
          isRead == other.isRead &&
          createdAt == other.createdAt);

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      title.hashCode ^
      body.hashCode ^
      titleAr.hashCode ^
      titleEn.hashCode ^
      bodyAr.hashCode ^
      bodyEn.hashCode ^
      type.hashCode ^
      isRead.hashCode ^
      createdAt.hashCode;

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
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
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      bodyAr: bodyAr ?? this.bodyAr,
      bodyEn: bodyEn ?? this.bodyEn,
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
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'type': type,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    debugPrint('################ Notification Received ################');
    debugPrint('Raw JSON: $json');

    // Handle data parsing safely
    Map<String, dynamic>? parsedData;
    if (json['data'] != null) {
      if (json['data'] is Map) {
        parsedData = Map<String, dynamic>.from(json['data'] as Map);
      } else if (json['data'] is String) {
        String dataStr = json['data'] as String;
        // Sometimes data comes as an unquoted string like "{winning_id: 56, payment_id: 18...}"
        // Let's try to extract key-value pairs if jsonDecode fails
        try {
          // Add import 'dart:convert'; to top of file if not present
          parsedData =
              json['data']
                  as Map<
                    String,
                    dynamic
                  >; // This would fail if it's actually String, handled below
        } catch (e) {
          debugPrint(
            'Error parsing notification payload normally, attempting manual parsing: $e',
          );
        }

        if (parsedData == null) {
          try {
            // Basic manual parsing of "{key: value, key2: value2}" format
            parsedData = {};
            String content = dataStr
                .replaceAll('{', '')
                .replaceAll('}', '')
                .trim();
            if (content.isNotEmpty) {
              List<String> pairs = content.split(',');
              for (String pair in pairs) {
                List<String> keyValue = pair.split(':');
                if (keyValue.length >= 2) {
                  String key = keyValue[0].trim();
                  // Rejoin in case value had colons
                  String value = keyValue.sublist(1).join(':').trim();
                  parsedData[key] = value;
                }
              }
            }
          } catch (e2) {
            debugPrint('Failed to manually parse notification data: $e2');
          }
        }
      }
    }

    debugPrint('Parsed data field type: ${parsedData?.runtimeType}');
    debugPrint('Parsed data field value: $parsedData');
    debugPrint('#######################################################');

    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? parsedData?['title_ar']?.toString(),
      titleEn: json['title_en'] as String? ?? parsedData?['title_en']?.toString(),
      bodyAr: json['body_ar'] as String? ?? parsedData?['body_ar']?.toString(),
      bodyEn: json['body_en'] as String? ?? parsedData?['body_en']?.toString(),
      type: json['type'] as String?,
      data: parsedData,
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

  String localizedTitleFor(String languageCode) {
    if (languageCode.toLowerCase().startsWith('ar')) {
      return titleAr?.isNotEmpty == true ? titleAr! : title;
    }

    return titleEn?.isNotEmpty == true ? titleEn! : title;
  }

  String localizedBodyFor(String languageCode) {
    if (languageCode.toLowerCase().startsWith('ar')) {
      return bodyAr?.isNotEmpty == true ? bodyAr! : body;
    }

    return bodyEn?.isNotEmpty == true ? bodyEn! : body;
  }

  String get localizedTitle => localizedTitleFor(Intl.getCurrentLocale());

  String get localizedBody => localizedBodyFor(Intl.getCurrentLocale());

  /// Get formatted title based on notification type or return raw title
  String get formattedTitle {
    return formattedTitleFor(Intl.getCurrentLocale());
  }

  String formattedTitleFor(String languageCode) {
    if (type == null) {
      return _localizedTitleFallback(localizedTitleFor(languageCode));
    }

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
      case 'PAYMENT_APPROVED':
        return AppStrings.notificationOrderStatus.tr();
      case 'PROMOTIONAL':
        return AppStrings.notificationSpecialOffer.tr();
      case 'AUCTION_ACCESS_APPROVED':
        return AppStrings.notificationAuctionAccessApproved.tr();
      default:
        return _localizedTitleFallback(localizedTitleFor(languageCode));
    }
  }

  String _localizedTitleFallback(String rawTitle) {
    switch (rawTitle.trim().toLowerCase()) {
      case 'auction access approved':
        return AppStrings.notificationAuctionAccessApproved.tr();
      case 'special offer':
        return AppStrings.notificationSpecialOffer.tr();
      default:
        return rawTitle;
    }
  }
}
