abstract class EndPoints {
  // base url
  //static const String baseUrl = "https://backend.barakkh.sa/";
  static String get baseUrl {
    return "https://144.91.124.224:4005/";
  }

  // auth
  static const String login = "auth/login";
  static const String userSignup = "auth/signup";
  static const String verifyOTP = "auth/otp";
  static const String resendOTP = "auth/resend-otp";
  static const String requestOTP = "auth/request-otp";
  static const String changePassword = "auth/change-password";
  static String getUser(int id) => "users/get-user?user_id=$id";

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
  static String getMyMaxBids = "auctions/get-my-max-bids";
  static String getMaxBids({int? auctionId, int? productId, int? userId}) {
    List<String> params = [];
    if (auctionId != null) params.add("auction_id=$auctionId");
    if (productId != null) params.add("product_id=$productId");
    if (userId != null) params.add("user_id=$userId");

    final query = params.isNotEmpty ? "?${params.join('&')}" : "";
    return "auctions/get-max-bids$query";
  }

  // Host/Creator
  static const String getUserProducts = "products/get-user-products";

  //live auction requests
  static const String addLiveAuctionRequest =
      "live-auction-requests/add-live-auction-request";

  // categories
  static const String allCategories = "categories/get-all-categories";

  //agora
  static const String getAgoraToken = "agora/token";

  static const String getUserOrders = 'order/get-user-orders';

  static const String addOrder = '/order/add-order';

  // Notifications
  static String getNotifications(int userId) => "notifications/$userId";
  static String markAsRead(int id) => "notifications/$id/read";
  static String markAllAsRead(int userId) => "notifications/read-all/$userId";
  static const String registerDevice = "notifications/register-device";
  static const String unregisterDevice = "notifications/unregister-device";

  // Product Orders
  static const String addProductOrder = '/order/add-product-order';

  // Cart
  static const String cart = 'cart';
  static const String cartAdd = 'cart/add';
  static const String cartRemove = 'cart/remove';
  static const String cartClear = 'cart/clear';

  // Products
  static const String getProducts = 'products/get-products';
  static const String getProduct = 'products/get-product';
  static const String addProduct = 'products/add-product';
  static const String editProduct = 'products/edit-product';
  static const String uploadProductImages = 'products/upload-images';

  // Search
  static const String search = 'search';

  // Likes
  static const String likes = 'likes';
  static const String likedProducts = 'likes/products';
  static const String likedAuctions = 'likes/auctions';

  // Auction Payments
  static const String uploadReceipt = 'auction-payments/upload-receipt';
  static const String myPayments = 'auction-payments/my-payments';

  // Addresses
  static const String getUserAddresses = 'addresses/get-user-addresses';
  static const String addAddress = 'addresses/add-address';
  static const String updateAddress = 'addresses/update-address';
  static const String deleteAddress = 'addresses/delete-address';

  // ============================================
  // App Config
  // ============================================

  static const String getConfig = 'config/get-app-config';

  // ============================================
  // Auction Access
  // ============================================

  static const String requestAuctionAccess = 'auction-access/request-access';
  static const String checkAuctionAccess = 'auction-access/check-access';
  static const String getMyAuctionRequests = 'auction-access/get-my-requests';
}
