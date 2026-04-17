import 'package:gd_payment_sdk/gd_payment_sdk.dart';

class GDPaymentSDKConfiguration {
  final SDKTheme? theme;
  final String sessionId;
  final String? applePayMerchantId;
  final SDKLanguage language;
  final Region region;

  const GDPaymentSDKConfiguration({
    this.theme,
    required this.sessionId,
    this.language = SDKLanguage.english,
    this.applePayMerchantId,
    this.region = Region.egy,
  });

  Map<String, dynamic> toJson() => {
    'theme': theme?.toJson(),
    'sessionId': sessionId,
    'language': language.toJson(),
    'applePayMerchantId': applePayMerchantId,
    'region': region.toJson(),
  };
}
