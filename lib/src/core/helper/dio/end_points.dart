/// {@category Core}
///
/// A constant collection of all API endpoints used by the application.
/// 
/// This class provides a centralized location for URL paths, preventing 
/// magic strings throughout the data layer. Methods are provided for 
/// endpoints requiring dynamic path or query parameters.
abstract class EndPoints {
  /// The root URL for all API calls.
  static String get baseUrl {
    // Development/Staging IP
    return "http://144.91.124.224/backend/";
  }

  // ── Authentication & User Identity ──────────────────────────────────────────
  
  /// Endpoint for user login.
  static const String login = "auth/login";
  
  /// Endpoint for initial user registration.
  static const String userSignup = "auth/signup";
  
  /// Endpoint for verifying an OTP code during registration or password reset.
  static const String verifyOTP = "auth/otp";
  
  /// Endpoint to request a new OTP code.
  static const String resendOTP = "auth/resend-otp";
  
  /// Endpoint to request a password reset OTP.
  static const String requestOTP = "auth/request-otp";
  
  /// Endpoint for updating the user's password.
  static const String changePassword = "auth/change-password";

  /// Endpoint for refreshing an expired user access token.
  static const String refreshToken = "auth/refresh";
  static const String googleLogin = "auth/google-login";
  static const String appleLogin = "auth/apple-login";
  
  /// Returns the path to fetch a specific user's public profile based on [id].
  static String getUser(int id) => "users/get-user?user_id=$id";
  
  /// Endpoint for updating user profile details.
  static const String updateUser = "users/update-user";

  /// Returns the path to upload a user profile picture based on [id].
  static String uploadProfilePicture(int id) => "users/profile-picture?user_id=$id";

  // ── Auctions ────────────────────────────────────────────────────────────────
  
  /// Endpoint to submit a new auction (Host feature).
  static const String addAuction = "auctions/add-auction";
  
  /// Endpoint to fetch auctions filtered by multiple categories.
  static const String getAuctionsByCategories = "auctions/get-auctions-by-categories";
  
  /// Endpoint to fetch all active and upcoming auctions.
  static const String getAllAuctions = "auctions/get-all-auctions";
  static const String getAuctionFilterOptions = "auctions/filter-options";

  /// Returns path for auctions filtered by a single category [id].
  static String getAuctionsByCategory({required int id}) =>
      "auctions/get-auctions-by-category?category_id=$id";

  /// Returns path for full details of a specific auction [id].
  static String getAuctionByID({required int id}) =>
      "auctions/get-auction?auction_id=$id";

  /// Endpoint to fetch auctions created by the current user.
  static String getUserAuctions = "auctions/get-user-auctions";

  /// Alias for [getAuctionByID].
  static String getAuction({required int id}) =>
      "auctions/get-auction?auction_id=$id";

  /// Endpoint to fetch auctions won by the current user.
  static String getWiningAuctions = "auctions/get-winnings";
  
  /// Endpoint to fetch the current user's highest bids across all auctions.
  static String getMyMaxBids = "auctions/get-my-max-bids";
  
  /// Builds a query string for fetching max bids with optional filters.
  /// 
  /// * [auctionId]: Filter by a specific auction.
  /// * [productId]: Filter by a specific product.
  /// * [userId]: Filter for a specific user's perspective.
  static String getMaxBids({int? auctionId, int? productId, int? userId}) {
    List<String> params = [];
    if (auctionId != null) params.add("auction_id=$auctionId");
    if (productId != null) params.add("product_id=$productId");
    if (userId != null) params.add("user_id=$userId");

    final query = params.isNotEmpty ? "?${params.join('&')}" : "";
    return "auctions/get-max-bids$query";
  }

  // ── Host / Seller Actions ───────────────────────────────────────────────────
  
  /// Endpoint to fetch products owned by the user.
  static const String getUserProducts = "products/get-user-products";
  
  /// Endpoint for requesting administrative approval to host a live auction.
  static const String addLiveAuctionRequest =
      "live-auction-requests/add-live-auction-request";

  // ── Catalog & Streaming ─────────────────────────────────────────────────────
  
  /// Endpoint to fetch the full taxonomy of available categories.
  static const String allCategories = "categories/get-all-categories";
  
  /// Fetches an RTB token from the server for Agora live stream authentication.
  static const String getAgoraToken = "agora/token";

  // ── Orders & Store ──────────────────────────────────────────────────────────
  
  /// Endpoint to fetch the order history of the current user.
  static const String getUserOrders = 'order/get-user-orders';
  
  /// Endpoint to create a new order (usually for auctions).
  static const String addOrder = '/order/add-order';
  
  /// Endpoint to create a direct product purchase order.
  static const String addProductOrder = '/order/add-product-order';
  
  /// Endpoint to upload proof of payment for store orders.
  static const String uploadStoreReceipt = 'order/upload-receipt';

  /// Returns the path to fetch trusted payment/order status for a specific order.
  static String getOrderPaymentStatus(int orderId) => 'payments/orders/$orderId/status';

  /// Endpoint to create a Geidea checkout session for a store order.
  static const String createGeideaSession = 'payments/geidea/session';

  /// Endpoint to create a Geidea standalone save-card session.
  static const String createGeideaSaveCardSession = 'payments/geidea/save-card/session';

  /// Endpoint to fetch the current user's saved payment methods.
  static const String savedPaymentMethods = 'payments/saved-methods';

  /// Endpoint to deactivate a saved payment method.
  static String deactivateSavedPaymentMethod(int methodId) =>
      'payments/saved-methods/$methodId/deactivate';

  /// Endpoint to set a saved payment method as default.
  static String setDefaultSavedPaymentMethod(int methodId) =>
      'payments/saved-methods/$methodId/default';

  // ── Notifications ───────────────────────────────────────────────────────────
  
  /// Returns the path to fetch notification history for user [userId].
  static String getNotifications(int userId) => "notifications/$userId";
  
  /// Returns the path to mark a specific notification [id] as read.
  static String markAsRead(int id) => "notifications/$id/read";
  
  /// Returns the path to mark all notifications for [userId] as read.
  static String markAllAsRead(int userId) => "notifications/read-all/$userId";
  
  /// Endpoint to register a mobile device for FCM push notifications.
  static const String registerDevice = "notifications/register-device";
  
  /// Endpoint to unregister a device from push notifications (Logout).
  static const String unregisterDevice = "notifications/unregister-device";

  // ── Cart Management ─────────────────────────────────────────────────────────
  
  /// Endpoint for basic cart operations.
  static const String cart = 'cart';
  
  /// Endpoint to add an item to the persistent server-side cart.
  static const String cartAdd = 'cart/add';
  
  /// Endpoint to remove an item from the cart.
  static const String cartRemove = 'cart/remove';
  
  /// Endpoint to clear all items from the user's cart.
  static const String cartClear = 'cart/clear';
  static const String preorders = 'preorders';
  static const String preorderCurrent = 'preorders/current';
  static const String preorderMyRequests = 'preorders/my-requests';
  static const String preorderAddItem = 'preorders/items/add';
  static String preorderUpdateQuantity(int productId, int quantity) =>
      'preorders/items/$productId/$quantity';
  static String preorderRemoveItem(int productId) => 'preorders/items/$productId';
  static const String preorderSubmit = 'preorders/submit';
  
  /// Returns path to synchronize a specific product quantity in the user's cart.
  static String cartUpdateQuantity(int userId, int productId, int quantity) =>
      'cart/quantity/$userId/$productId/$quantity';

  // ── Store Products ──────────────────────────────────────────────────────────
  
  /// Endpoint to fetch a paginated list of catalog products.
  static const String getProducts = 'products/get-products';
  static const String getProductFilterOptions = 'products/filter-options';
  
  /// Endpoint to fetch full details for a single product.
  static const String getProduct = 'products/get-product';
  
  /// Endpoint for sellers to add a new product.
  static const String addProduct = 'products/add-product';
  
  /// Endpoint for sellers to edit existing product details.
  static const String editProduct = 'products/edit-product';
  
  /// Endpoint to upload gallery images for a product.
  static const String uploadProductImages = 'products/upload-images';

  // ── Search & Social ─────────────────────────────────────────────────────────
  
  /// Endpoint for global text-based search.
  static const String search = 'search';
  
  /// Endpoint for basic 'Like' interactions.
  static const String likes = 'likes';
  
  /// Endpoint to fetch products favorited by the user.
  static const String likedProducts = 'likes/products';
  
  /// Endpoint to fetch auctions favorited by the user.
  static const String likedAuctions = 'likes/auctions';

  // ── Financial Records ───────────────────────────────────────────────────────
  
  /// Endpoint to upload proof of payment for an auction win.
  static const String uploadReceipt = 'auction-payments/upload-receipt';
  
  /// Endpoint to fetch the user's auction payment history and status.
  static const String myPayments = 'auction-payments/my-payments';

  // ── User Profile Data ───────────────────────────────────────────────────────
  
  /// Endpoint to fetch the user's saved shipping addresses.
  static const String getUserAddresses = 'addresses/get-user-addresses';
  
  /// Endpoint to save a new shipping address.
  static const String addAddress = 'addresses/add-address';
  
  /// Endpoint to update an existing shipping address.
  static const String updateAddress = 'addresses/update-address';
  
  /// Endpoint to remove a specific shipping address.
  static const String deleteAddress = 'addresses/delete-address';

  // ── System Configuration ────────────────────────────────────────────────────
  
  /// Endpoint to fetch remote application settings (e.g., maintenance mode, versioning).
  static const String getConfig = 'config/get-app-config';

  // ── Auction Access Control ──────────────────────────────────────────────────
  
  /// Endpoint to request participation access for a specific auction.
  static const String requestAuctionAccess = 'auction-access/request-access';
  
  /// Endpoint to check the current user's permission status for an auction.
  static const String checkAuctionAccess = 'auction-access/check-access';
  
  /// Endpoint to fetch the user's pending or approved auction access requests.
  static const String getMyAuctionRequests = 'auction-access/get-my-requests';
}
