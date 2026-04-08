import 'dart:developer' show log;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:turathy/src/features/authintication/domain/user_model.dart';

/// Centralized Firebase Analytics helper for the most important app flows.
abstract class AnalyticsService {
  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Associates the current Firebase session with the active user.
  static Future<void> setUser(
    UserModel? user, {
    String? authMethod,
  }) async {
    try {
      await _analytics.setUserId(id: user?.id?.toString());
      if (authMethod != null) {
        await _analytics.setUserProperty(name: 'auth_method', value: authMethod);
      }
      await _analytics.setUserProperty(
        name: 'profile_complete',
        value: user?.isProfileComplete?.toString(),
      );
    } catch (error, stackTrace) {
      log('Failed to set analytics user context: $error', stackTrace: stackTrace);
    }
  }

  /// Clears the current Firebase user association after logout.
  static Future<void> clearUser() async {
    try {
      await _analytics.setUserId(id: null);
      await _analytics.setUserProperty(name: 'auth_method', value: null);
      await _analytics.setUserProperty(name: 'profile_complete', value: null);
    } catch (error, stackTrace) {
      log('Failed to clear analytics user context: $error', stackTrace: stackTrace);
    }
  }

  /// Logs a screen view.
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (error, stackTrace) {
      log('Failed to log screen view: $error', stackTrace: stackTrace);
    }
  }

  /// Logs a successful sign-up.
  static Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (error, stackTrace) {
      log('Failed to log sign up: $error', stackTrace: stackTrace);
    }
  }

  /// Logs a successful login.
  static Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (error, stackTrace) {
      log('Failed to log login: $error', stackTrace: stackTrace);
    }
  }

  /// Logs a product detail view.
  static Future<void> logProductViewed({
    required int productId,
    String? category,
    double? price,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'product_viewed',
        parameters: {
          'product_id': productId,
          if (category != null && category.isNotEmpty) 'category': category,
          if (price != null) 'price': price,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log product view: $error', stackTrace: stackTrace);
    }
  }

  /// Logs an auction detail view.
  static Future<void> logAuctionViewed({
    required int auctionId,
    String? category,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'auction_viewed',
        parameters: {
          'auction_id': auctionId,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log auction view: $error', stackTrace: stackTrace);
    }
  }

  /// Logs when a user joins a live auction.
  static Future<void> logAuctionJoined({required int auctionId}) async {
    try {
      await _analytics.logEvent(
        name: 'auction_joined',
        parameters: {'auction_id': auctionId},
      );
    } catch (error, stackTrace) {
      log('Failed to log auction join: $error', stackTrace: stackTrace);
    }
  }

  /// Logs a bid placement attempt.
  static Future<void> logBidPlaced({
    required int auctionId,
    required int productId,
    required double amount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'bid_placed',
        parameters: {
          'auction_id': auctionId,
          'product_id': productId,
          'amount': amount,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log bid placement: $error', stackTrace: stackTrace);
    }
  }

  /// Logs when a user requests access to a restricted auction.
  static Future<void> logAuctionAccessRequested({required int auctionId}) async {
    try {
      await _analytics.logEvent(
        name: 'auction_access_requested',
        parameters: {'auction_id': auctionId},
      );
    } catch (error, stackTrace) {
      log('Failed to log auction access request: $error', stackTrace: stackTrace);
    }
  }

  /// Logs add-to-cart interactions.
  static Future<void> logAddToCart({
    required int productId,
    required int quantity,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'add_to_cart',
        parameters: {
          'product_id': productId,
          'quantity': quantity,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log add to cart: $error', stackTrace: stackTrace);
    }
  }

  /// Logs that checkout has started.
  static Future<void> logBeginCheckout({
    required double value,
    required int itemCount,
    required bool hasAuctionItems,
  }) async {
    try {
      await _analytics.logBeginCheckout(
        value: value,
        currency: 'SAR',
        items: const [],
      );
      await _analytics.logEvent(
        name: 'checkout_context',
        parameters: {
          'item_count': itemCount,
          'has_auction_items': hasAuctionItems,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log begin checkout: $error', stackTrace: stackTrace);
    }
  }

  /// Logs a completed purchase.
  static Future<void> logPurchase({
    required String orderId,
    required double value,
    required int itemCount,
    required bool hasAuctionItems,
  }) async {
    try {
      await _analytics.logPurchase(
        transactionId: orderId,
        value: value,
        currency: 'SAR',
        items: const [],
      );
      await _analytics.logEvent(
        name: 'purchase_context',
        parameters: {
          'item_count': itemCount,
          'has_auction_items': hasAuctionItems,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log purchase: $error', stackTrace: stackTrace);
    }
  }

  /// Logs when a payment receipt is submitted.
  static Future<void> logPaymentSubmitted({
    required int orderId,
    required double amount,
    required String method,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'payment_submitted',
        parameters: {
          'order_id': orderId,
          'amount': amount,
          'method': method,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log payment submitted: $error', stackTrace: stackTrace);
    }
  }

  /// Logs search usage.
  static Future<void> logSearch({
    required String term,
    required int resultCount,
  }) async {
    try {
      await _analytics.logSearch(searchTerm: term);
      await _analytics.logEvent(
        name: 'search_results_count',
        parameters: {
          'result_count': resultCount,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log search: $error', stackTrace: stackTrace);
    }
  }

  /// Logs product filter usage.
  static Future<void> logFilterApplied({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? country,
    bool? isGraded,
    int activeFilterCount = 0,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'filter_applied',
        parameters: {
          if (category != null && category.isNotEmpty) 'category': category,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          if (country != null && country.isNotEmpty) 'country': country,
          if (isGraded != null) 'is_graded': isGraded.toString(),
          'active_filter_count': activeFilterCount,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log filter applied: $error', stackTrace: stackTrace);
    }
  }

  /// Logs category navigation and discovery behavior.
  static Future<void> logCategorySelected({
    required int categoryId,
    required String categoryName,
    String source = 'unknown',
  }) async {
    try {
      await _analytics.logEvent(
        name: 'category_selected',
        parameters: {
          'category_id': categoryId,
          'category_name': categoryName,
          'source': source,
        },
      );
    } catch (error, stackTrace) {
      log(
        'Failed to log category selection: $error',
        stackTrace: stackTrace,
      );
    }
  }

  /// Logs notification tap opens.
  static Future<void> logNotificationOpened({
    String? type,
    String? auctionId,
    String? productId,
    String? orderId,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'notification_opened',
        parameters: {
          if (type != null && type.isNotEmpty) 'type': type,
          if (auctionId != null && auctionId.isNotEmpty) 'auction_id': auctionId,
          if (productId != null && productId.isNotEmpty) 'product_id': productId,
          if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        },
      );
    } catch (error, stackTrace) {
      log('Failed to log notification open: $error', stackTrace: stackTrace);
    }
  }
}
