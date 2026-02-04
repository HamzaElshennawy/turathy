import 'package:flutter/foundation.dart';

abstract class EndPoints {
  // base url
  //static const String baseUrl = "https://backend.barakkh.sa/";
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:4005/";
    if (defaultTargetPlatform == TargetPlatform.android)
      return "https://10.0.2.2:4005/";
    return "http://localhost:4005/";
  }

  // auth
  static const String login = "auth/login";
  static const String userSignup = "auth/signup";
  static const String verifyOTP = "auth/otp";
  static const String resendOTP = "auth/resend-otp";
  static const String requestOTP = "auth/request-otp";
  static const String changePassword = "auth/change-password";

  // Auctions
  static const String addAuction = "auctions/add-auction";
  static const String getAuctionsByCategories =
      "auctions/get-auctions-by-categories";
  static const String getAllAuctions = "auctions/get-all-auctions";

  static String getAuctionsByCategory({required int id}) =>
      "auctions/get-auctions-by-category?category_id=$id";

  static String getAuctionByID({required int id}) =>
      "auctions/get-auction?auction_id=$id";

  static String getUserAuctions = "auctions/get-user-auctions";

  static String getAuction({required int id}) =>
      "auctions/get-auction?auction_id=$id";

  static String getWiningAuctions = "auctions/get-winnings";

  //live auction requests
  static const String addLiveAuctionRequest =
      "live-auction-requests/add-live-auction-request";

  // categories
  static const String allCategories = "categories/get-all-categories";

  //agora
  static const String getAgoraToken = "agora/token";

  static const String addOrder = '/order/add-order';

  // Notifications
  static String getNotifications(int userId) => "notifications/$userId";
  static String markAsRead(int id) => "notifications/$id/read";
  static String markAllAsRead(int userId) => "notifications/read-all/$userId";
  static const String registerDevice = "notifications/register-device";
  static const String unregisterDevice = "notifications/unregister-device";
}
