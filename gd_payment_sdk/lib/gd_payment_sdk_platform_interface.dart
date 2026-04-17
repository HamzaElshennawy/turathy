// © 2026 Geidea. Proprietary and confidential.
// Unauthorized copying or redistribution is prohibited.

import 'package:flutter/services.dart';
import 'package:gd_payment_sdk/gd_payment_sdk.dart';

class GdPaymentSdkPlatform {
  static const MethodChannel _channel = MethodChannel('gd_payment_sdk');

  Future<PaymentResponse> start({
    required GDPaymentSDKConfiguration configuration,
    SDKPresentationStyle presentationStyle = const PushStyle(),
  }) async {
    try {
      final result = await _channel.invokeMethod('start', {
        'configuration': configuration.toJson(),
        'presentationStyle': presentationStyle.toJson(),
      });

      // Parse the result map
      if (result is Map) {
        final resultMap = _convertMap(result);
        final status = resultMap['status'] as String?;

        switch (status) {
          case 'success':
            final dataRaw = resultMap['data'];
            if (dataRaw != null) {
              final data = _convertMap(dataRaw);
              final paymentResult = GDPaymentResult.fromJson(data);
              return PaymentResponse.success(paymentResult);
            } else {
              throw Exception('Success response missing data');
            }

          case 'canceled':
            return PaymentResponse.canceled();

          default:
            throw Exception('Unknown payment status: $status');
        }
      } else {
        throw Exception('Invalid response format');
      }
    } on PlatformException catch (e) {
      // Handle error responses
      final details = e.details != null ? _convertMap(e.details) : null;
      final error = GDPaymentError(
        code: e.code,
        message: e.message ?? 'Unknown error',
        details: details?.toString(),
      );
      return PaymentResponse.failure(error);
    } catch (e) {
      // Handle unexpected errors
      final error = GDPaymentError(
        code: 'UNKNOWN_ERROR',
        message: e.toString(),
      );
      return PaymentResponse.failure(error);
    }
  }

  // Helper method to safely convert maps from platform channel
  Map<String, dynamic> _convertMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      return Map<String, dynamic>.from(
        value.map(
          (key, value) => MapEntry(key.toString(), _convertValue(value)),
        ),
      );
    }
    throw Exception('Cannot convert value to Map<String, dynamic>');
  }

  // Helper method to recursively convert nested values
  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return _convertMap(value);
    } else if (value is List) {
      return value.map((item) => _convertValue(item)).toList();
    }
    return value;
  }
}
