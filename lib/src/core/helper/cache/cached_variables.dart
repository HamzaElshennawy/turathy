/// {@category Core}
///
/// Global in-memory cache for frequently accessed session and application data.
/// 
/// This utility class stores data that is synchronized from persistent storage
/// (like Secure Storage or Shared Preferences) during app initialization or 
/// authentication. Using these static variables allows synchronous access to 
/// session data (e.g., [token], [userId]) without repeated asynchronous reads.
abstract class CachedVariables {
  /// The Bearer authentication token for the current session.
  static String? token;
  
  /// The unique ID of the currently logged-in user.
  static int? userId;
  
  /// The display name or nickname of the user.
  static String? userName;
  
  /// The user's email address.
  static String? email;
  
  /// The user's mobile number, stored in E.164 format.
  static String? phone_number;
  
  /// The user's encrypted or session password (used for specific re-auth flows).
  static String? password;
  
  /// Track whether the user has completed the onboarding flow.
  static String? onBoard;
  
  /// The current app language code (e.g., 'ar', 'en').
  static String? lang;
  
  /// The unique Firebase Cloud Messaging token for push notifications.
  static String? fcmToken;
  
  /// Indicates if the user is authenticated via Google Sign-In.
  static bool isGoogleSignIn = false;
}


