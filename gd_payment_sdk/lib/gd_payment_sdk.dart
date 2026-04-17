// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

library;

import 'package:gd_payment_sdk/gd_payment_sdk_platform_interface.dart';
import 'package:gd_payment_sdk/src/models/configuration.dart';
import 'package:gd_payment_sdk/src/models/payment_result.dart';
import 'package:gd_payment_sdk/src/models/presentation_style.dart';

export 'src/models/configuration.dart';
export 'src/models/enums.dart';
export 'src/models/payment_result.dart';
export 'src/models/presentation_style.dart';
export 'src/models/theme.dart';

class GDPaymentSDK {
  static final GDPaymentSDK _instance = GDPaymentSDK._internal();
  final GdPaymentSdkPlatform _platform = GdPaymentSdkPlatform();

  factory GDPaymentSDK.sharedInstance() => _instance;

  GDPaymentSDK._internal();

  Future<PaymentResponse> start({
    required GDPaymentSDKConfiguration configuration,
    SDKPresentationStyle presentationStyle = const PushStyle(),
  }) async {
    return await _platform.start(
      configuration: configuration,
      presentationStyle: presentationStyle,
    );
  }
}
