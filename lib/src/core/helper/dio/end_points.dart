abstract class EndPoints {
  // base url
  static const String baseUrl = "https://backend.barakkh.sa/";

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
}
