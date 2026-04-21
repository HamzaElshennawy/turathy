import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../authintication/data/auth_repository.dart';
import '../domain/geidea_checkout_session_model.dart';
import '../domain/saved_payment_method_model.dart';
import '../utils/payment_debug_logger.dart';

class PaymentsRepository {
  Future<GeideaCheckoutSessionModel> createGeideaSession({
    required int orderId,
    bool cardOnFile = false,
    int? savedMethodId,
    String language = 'en',
    String? returnUrl,
  }) async {
    PaymentDebugLogger.info('createGeideaSession:request', data: {
      'url': EndPoints.createGeideaSession,
      'orderId': orderId,
      'cardOnFile': cardOnFile,
      'savedMethodId': savedMethodId,
      'language': language,
      'returnUrl': returnUrl,
    });
    final response = await DioHelper.postData(
      url: EndPoints.createGeideaSession,
      token: CachedVariables.token,
      data: {
        'order_id': orderId,
        'cardOnFile': cardOnFile,
        if (savedMethodId != null) 'saved_method_id': savedMethodId,
        'language': language,
        if (returnUrl != null) 'returnUrl': returnUrl,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final payload = Map<String, dynamic>.from(response.data['data'] as Map);
      PaymentDebugLogger.info('createGeideaSession:success', data: {
        'statusCode': response.statusCode,
        'response': payload,
      });
      return GeideaCheckoutSessionModel.fromJson(
        payload,
      );
    }

    final message =
        response.data['error'] ??
        'An error occurred while creating the Geidea checkout session';
    PaymentDebugLogger.error(
      'createGeideaSession:failure',
      error: message,
      data: {
        'statusCode': response.statusCode,
        'response': response.data is Map
            ? Map<String, Object?>.from(response.data as Map)
            : {'response': response.data.toString()},
      },
    );
    throw AuthException(message, response.statusCode);
  }

  Future<GeideaCheckoutSessionModel> createGeideaSaveCardSession({
    String language = 'en',
    String? returnUrl,
  }) async {
    PaymentDebugLogger.info('createGeideaSaveCardSession:request', data: {
      'url': EndPoints.createGeideaSaveCardSession,
      'language': language,
      'returnUrl': returnUrl,
    });
    final response = await DioHelper.postData(
      url: EndPoints.createGeideaSaveCardSession,
      token: CachedVariables.token,
      data: {
        'language': language,
        if (returnUrl != null) 'returnUrl': returnUrl,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final payload = Map<String, dynamic>.from(response.data['data'] as Map);
      PaymentDebugLogger.info('createGeideaSaveCardSession:success', data: {
        'statusCode': response.statusCode,
        'response': payload,
      });
      return GeideaCheckoutSessionModel.fromJson(
        payload,
      );
    }

    final message =
        response.data['error'] ??
        'An error occurred while creating the Geidea save-card session';
    PaymentDebugLogger.error(
      'createGeideaSaveCardSession:failure',
      error: message,
      data: {
        'statusCode': response.statusCode,
        'response': response.data is Map
            ? Map<String, Object?>.from(response.data as Map)
            : {'response': response.data.toString()},
      },
    );
    throw AuthException(message, response.statusCode);
  }

  Future<List<SavedPaymentMethodModel>> listSavedPaymentMethods({
    required int userId,
  }) async {
    PaymentDebugLogger.info('listSavedPaymentMethods:request', data: {
      'url': EndPoints.savedPaymentMethods,
      'userId': userId,
    });
    final response = await DioHelper.getData(
      url: EndPoints.savedPaymentMethods,
      token: CachedVariables.token,
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as List? ?? const [];
      PaymentDebugLogger.info('listSavedPaymentMethods:success', data: {
        'statusCode': response.statusCode,
        'count': data.length,
      });
      return data
          .map(
            (item) => SavedPaymentMethodModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }

    final message =
        response.data['error'] ??
        'An error occurred while fetching saved payment methods';
    PaymentDebugLogger.error(
      'listSavedPaymentMethods:failure',
      error: message,
      data: {
        'statusCode': response.statusCode,
        'response': response.data is Map
            ? Map<String, Object?>.from(response.data as Map)
            : {'response': response.data.toString()},
      },
    );
    throw AuthException(message, response.statusCode);
  }

  Future<SavedPaymentMethodModel> deactivateSavedPaymentMethod({
    required int userId,
    required int methodId,
  }) async {
    PaymentDebugLogger.info('deactivateSavedPaymentMethod:request', data: {
      'url': EndPoints.deactivateSavedPaymentMethod(methodId),
      'userId': userId,
      'methodId': methodId,
    });
    final response = await DioHelper.postData(
      url: EndPoints.deactivateSavedPaymentMethod(methodId),
      token: CachedVariables.token,
      data: const {},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      PaymentDebugLogger.info('deactivateSavedPaymentMethod:success', data: {
        'statusCode': response.statusCode,
        'methodId': methodId,
      });
      return SavedPaymentMethodModel.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
    }

    final message =
        response.data['error'] ??
        'An error occurred while deactivating the saved payment method';
    PaymentDebugLogger.error(
      'deactivateSavedPaymentMethod:failure',
      error: message,
      data: {
        'statusCode': response.statusCode,
        'methodId': methodId,
      },
    );
    throw AuthException(message, response.statusCode);
  }

  Future<SavedPaymentMethodModel> setDefaultSavedPaymentMethod({
    required int userId,
    required int methodId,
  }) async {
    PaymentDebugLogger.info('setDefaultSavedPaymentMethod:request', data: {
      'url': EndPoints.setDefaultSavedPaymentMethod(methodId),
      'userId': userId,
      'methodId': methodId,
    });
    final response = await DioHelper.postData(
      url: EndPoints.setDefaultSavedPaymentMethod(methodId),
      token: CachedVariables.token,
      data: const {},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      PaymentDebugLogger.info('setDefaultSavedPaymentMethod:success', data: {
        'statusCode': response.statusCode,
        'methodId': methodId,
      });
      return SavedPaymentMethodModel.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
    }

    final message =
        response.data['error'] ??
        'An error occurred while setting the default payment method';
    PaymentDebugLogger.error(
      'setDefaultSavedPaymentMethod:failure',
      error: message,
      data: {
        'statusCode': response.statusCode,
        'methodId': methodId,
      },
    );
    throw AuthException(message, response.statusCode);
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository();
});
