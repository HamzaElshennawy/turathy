import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gd_payment_sdk/gd_payment_sdk.dart';

import '../../../core/constants/app_strings/app_strings.dart';
import '../domain/geidea_checkout_session_model.dart';
import '../utils/payment_debug_logger.dart';

enum GeideaPaymentOutcomeStatus { success, failure, canceled }

class GeideaPaymentOutcome {
  const GeideaPaymentOutcome({
    required this.status,
    this.message,
    this.raw = const <String, Object?>{},
  });

  final GeideaPaymentOutcomeStatus status;
  final String? message;
  final Map<String, Object?> raw;
}

class GeideaSdkService {
  const GeideaSdkService();

  static const String _configuredRegion = String.fromEnvironment(
    'GEIDEA_REGION',
    defaultValue: '',
  );
  static const String _applePayMerchantId = String.fromEnvironment(
    'GEIDEA_APPLE_PAY_MERCHANT_ID',
    defaultValue: '',
  );

  Future<GeideaPaymentOutcome> startCheckout({
    required BuildContext context,
    required GeideaCheckoutSessionModel session,
    required ThemeData theme,
  }) async {
    final sessionId = session.sessionId?.trim();
    if (sessionId == null || sessionId.isEmpty) {
      throw StateError('Geidea sessionId is missing from the backend response.');
    }

    final region = _resolveRegion(session);
    final language = _resolveLanguage(context.locale);
    final configuration = GDPaymentSDKConfiguration(
      sessionId: sessionId,
      region: region,
      language: language,
      applePayMerchantId: _applePayMerchantId.trim().isEmpty
          ? null
          : _applePayMerchantId.trim(),
    );

    PaymentDebugLogger.info(
      'GeideaSdkService:startCheckout:prepared',
      data: {
        'merchantReferenceId': session.merchantReferenceId,
        'sessionId': sessionId,
        'region': region.name,
        'language': language.name,
        'presentationStyle': 'present',
        'configuration': configuration.toJson(),
      },
    );

    try {
      final response = await GDPaymentSDK.sharedInstance().start(
        configuration: configuration,
        presentationStyle: const PresentStyle(),
      );

      return _mapResponse(response);
    } catch (error, stackTrace) {
      PaymentDebugLogger.error(
        'GeideaSdkService:startCheckout:exception',
        error: error,
        stackTrace: stackTrace,
        data: {
          'merchantReferenceId': session.merchantReferenceId,
          'sessionId': sessionId,
        },
      );
      return GeideaPaymentOutcome(
        status: GeideaPaymentOutcomeStatus.failure,
        message: error.toString(),
        raw: {'error': error.toString()},
      );
    }
  }

  GeideaPaymentOutcome _mapResponse(PaymentResponse response) {
    final raw = <String, Object?>{
      'status': response.status.name,
      if (response.result != null) 'result': response.result!.toJson(),
      if (response.error != null) 'error': response.error!.toJson(),
    };

    switch (response.status) {
      case PaymentStatus.success:
        return GeideaPaymentOutcome(
          status: GeideaPaymentOutcomeStatus.success,
          message: null,
          raw: raw,
        );
      case PaymentStatus.failure:
        return GeideaPaymentOutcome(
          status: GeideaPaymentOutcomeStatus.failure,
          message:
              response.error?.details ??
              response.error?.message ??
              AppStrings.paymentFailed.tr(),
          raw: raw,
        );
      case PaymentStatus.canceled:
        return GeideaPaymentOutcome(
          status: GeideaPaymentOutcomeStatus.canceled,
          message: AppStrings.geideaCheckoutCanceled.tr(),
          raw: raw,
        );
    }
  }

  SDKLanguage _resolveLanguage(Locale locale) {
    return locale.languageCode.toLowerCase().startsWith('ar')
        ? SDKLanguage.arabic
        : SDKLanguage.english;
  }

  Region _resolveRegion(GeideaCheckoutSessionModel session) {
    final configured = _configuredRegion.trim().toLowerCase();
    if (configured.isNotEmpty) {
      return _regionFromValue(configured);
    }

    final currency = _readString(session.rawResponse, const [
      'currency',
      'orderCurrency',
    ])?.toUpperCase();
    switch (currency) {
      case 'SAR':
        return Region.ksa;
      case 'AED':
        return Region.uae;
      case 'EGP':
        return Region.egy;
      default:
        return Region.ksa;
    }
  }

  Region _regionFromValue(String value) {
    switch (value) {
      case 'ksa':
      case 'sa':
      case 'saudi':
      case 'saudi-arabia':
      case 'saudi_arabia':
      case 'sar':
        return Region.ksa;
      case 'uae':
      case 'ae':
      case 'emirates':
      case 'aed':
        return Region.uae;
      case 'egy':
      case 'eg':
      case 'egypt':
      case 'egp':
        return Region.egy;
      default:
        throw StateError(
          'Unsupported GEIDEA_REGION value "$value". Use ksa, uae, or egy.',
        );
    }
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final nestedSession = data['session'];
    if (nestedSession is Map<String, dynamic>) {
      return _readString(nestedSession, keys);
    }

    return null;
  }
}
