/// {@category Routing}
///
/// Centralized route name and path definitions for the application.
/// 
/// This class ensures consistency across the app's navigation system, 
/// providing a single source of truth for GoRouter paths and deep links.
class RouteConstants {
  /// Initial landing/splash screen.
  static const String init = "/";

  /// Authentication entry point.
  static const String signIn = "/sign-in";

  /// New user registration.
  static const String signUp = "/sign-up";

  /// Main application shell (contains the home features).
  static const String home = "/home";

  /// User profile and settings.
  static const String profile = "/profile";

  /// Post-signup profile data completion.
  static const String completeProfile = "/complete-profile";

  /// Password recovery flow.
  static const String inputEmailForgotPassword = "/inputEmailForgotPassword";

  /// Real-time auction room for a specific [id].
  static const String liveAuction = "/live-auction/:id";

  /// Product catalog details for a specific [id].
  static const String productDetails = "/product-details/:id";

  /// History of user orders.
  static const String orders = "/orders";

  /// Specific order summary and tracking for [id].
  static const String orderDetails = "/order-details/:id";

  /// Detailed static information about an auction for [id].
  static const String auctionDetails = "/auction-details/:id";
}

