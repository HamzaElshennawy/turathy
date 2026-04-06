/// {@category Constants}
///
/// Registry of all static asset paths used in the application.
/// 
/// This class centralizes paths for:
/// - Brand identity (Logos).
/// - UI Fallbacks (Placeholders).
/// - Decorative illustrations (SVGs for sentiment/feedback).
class AppImages {
  /// The primary corporate logo.
  static const String logo = "assets/images/logo.png";

  /// Standard fallback image for missing network assets.
  static const String placeHolder = "assets/images/place_holder.png";

  // ── Sentiment Icons (SVGs) ──────────────────────────────────────────────────
  static const String sad = "assets/images/sad.svg";
  static const String disappointed = "assets/images/disappointed.svg";
  static const String dissatisfied = "assets/images/dissatisfied.svg";
  static const String friendly = "assets/images/friendly.svg";
  static const String smiley = "assets/images/smiley.svg";
  static const String surprised = "assets/images/surprised.svg";
}
