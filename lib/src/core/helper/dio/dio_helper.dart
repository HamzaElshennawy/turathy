/// {@category Core}
///
/// A singleton helper class for handling all HTTP networking requests via the [Dio] package.
///
/// This class centralizes base configuration, common headers, authentication token
/// management, and interceptors for logging and global error handling (e.g., 401 redirects).
library;

import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';

import '../../../features/authintication/data/auth_repository.dart';
import '../../../features/orders/utils/payment_debug_logger.dart';
import '../../../routing/app_router.dart';
import '../../../routing/rout_constants.dart';
import '../../common_widgets/no_internet_dialog.dart';
import 'end_points.dart';

/// Manages a global [Dio] instance with customized interceptors and base options.
///
/// Provides a unified interface for GET, POST, PUT, PATCH, and DELETE operations
/// while enforcing consistent headers and error handling across the entire app.
class DioHelper {
  /// The global [Dio] instance used for all network requests.
  static late Dio dio;

  /// Track whether the "No Internet" dialog is currently visible to prevent multiple overlays.
  static bool _isShowingNoInternetDialog = false;
  static bool _isRefreshingToken = false;

  static bool _isPaymentUrl(String url) {
    return url.contains('payments/') ||
        url.contains('order/upload-receipt') ||
        url.contains('auction-payments/') ||
        url.contains('order/add-order') ||
        url.contains('order/add-product-order') ||
        url.contains('order/update-order');
  }

  static Map<String, Object?> _responseSnapshot(Response response) {
    final data = response.data;
    if (data is Map) {
      return Map<String, Object?>.from(data);
    }
    if (data is List) {
      return {'listLength': data.length, 'data': data};
    }
    return {'data': data?.toString()};
  }

  /// Initializes the [Dio] instance with base configuration and interceptors.
  ///
  /// Sets up:
  /// - Base URL from [EndPoints.baseUrl].
  /// - Status validation (returns true for all to allow manual handling).
  /// - Custom HTTP client for non-web platforms (allowing self-signed certs).
  /// - [PrettyDioLogger] for debug logging.
  /// - Response Interceptor: Handles 401 Unauthorized by clearing local auth and redirecting to Sign In.
  /// - Error Interceptor: Displays [NoInternetDialog] on connection/timeout errors.
  static void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: EndPoints.baseUrl,
        receiveDataWhenStatusError: true,
        followRedirects: false,
        // Status codes are handled manually in repositories to allow custom error handling
        validateStatus: (status) => true,
      ),
    );

    log(
      'DioHelper: Initialized with baseUrl: ${EndPoints.baseUrl}',
      time: DateTime.now(),
    );

    if (!kIsWeb) {
      // Configuration to allow self-signed certificates in development environments
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    // Keep network logging minimal and debug-only to avoid leaking tokens or payment payloads.
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    // Standard interceptor for global response and error handling
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          // Detect unauthorized status (401) globally
          if (response.statusCode == 401) {
            // Avoid redirection loops during authentication attempts
            if (response.requestOptions.path == EndPoints.login ||
                response.requestOptions.path == EndPoints.userSignup ||
                response.requestOptions.path == EndPoints.refreshToken) {
              return handler.next(response);
            }
            final retried = await _tryRefreshAndRetry(response.requestOptions);
            if (retried != null) {
              return handler.resolve(retried);
            }
            goRouter.push(RouteConstants.signIn);
            AuthRepository.clearLocalDetails();
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Handle connection-related exceptions with a global UI dialog
          if (error.response?.statusCode == 401) {
            if (error.requestOptions.path != EndPoints.refreshToken) {
              final retried = await _tryRefreshAndRetry(error.requestOptions);
              if (retried != null) {
                return handler.resolve(retried);
              }
            }
            goRouter.push(RouteConstants.signIn);
            AuthRepository.clearLocalDetails();
          } else if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.unknown) {
            final context = rootNavigatorKey.currentContext;
            if (context != null && !_isShowingNoInternetDialog) {
              _isShowingNoInternetDialog = true;
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) => const NoInternetDialog(),
              );
              _isShowingNoInternetDialog = false;
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Performs an asynchronous GET request.
  ///
  /// * [url]: The endpoint path.
  /// * [query]: Optional URL query parameters.
  /// * [lang]: Language code for content localization.
  /// * [token]: Bearer authentication token.
  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
    String lang = 'en',
    String? token,
  }) async {
    try {
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        "Accept": "application/json",
        "lang": lang,
      };
      if (_isPaymentUrl(url)) {
        PaymentDebugLogger.info(
          'DioHelper.GET:request',
          data: {'url': url, 'query': query, 'lang': lang},
        );
      }
      final response = await dio.get(
        url,
        queryParameters: query,
        options: Options(
          validateStatus: (_) => true,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
      if (_isPaymentUrl(url)) {
        PaymentDebugLogger.info(
          'DioHelper.GET:response',
          data: {
            'url': url,
            'statusCode': response.statusCode,
            'response': _responseSnapshot(response),
          },
        );
      }
      return response;
    } catch (error) {
      if (_isPaymentUrl(url)) {
        PaymentDebugLogger.error(
          'DioHelper.GET:error',
          error: error,
          data: {'url': url, 'query': query},
        );
      }
      log('DioHelper (GET): $error');
      rethrow;
    }
  }

  static Future<Response<dynamic>?> _tryRefreshAndRetry(
    RequestOptions requestOptions,
  ) async {
    if (_isRefreshingToken ||
        requestOptions.extra['retriedAfterRefresh'] == true) {
      return null;
    }

    _isRefreshingToken = true;
    try {
      final refreshed = await AuthRepository.refreshAccessToken();
      if (!refreshed || CachedVariables.token == null) {
        return null;
      }

      final options = Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer ${CachedVariables.token}',
        },
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
        validateStatus: (_) => true,
        extra: {...requestOptions.extra, 'retriedAfterRefresh': true},
      );

      return dio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options,
      );
    } finally {
      _isRefreshingToken = false;
    }
  }

  /// Performs an asynchronous POST request.
  ///
  /// * [url]: The target endpoint.
  /// * [data]: The payload body (Map or FormData).
  /// * [isMultipart]: true if the request contains files.
  /// * [token]: Security bearer token.
  static Future<Response> postData({
    required String url,
    Map<String, dynamic>? query,
    dynamic data,
    String lang = 'en',
    String? token,
    bool isMultipart = false,
  }) async {
    try {
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        "Accept": "application/json",
        "lang": lang,
        if (!isMultipart) "Content-Type": "application/json",
      };
      if (_isPaymentUrl(url)) {
        PaymentDebugLogger.info(
          'DioHelper.POST:request',
          data: {
            'url': url,
            'query': query,
            'lang': lang,
            'isMultipart': isMultipart,
            'data': isMultipart
                ? {'multipart': true}
                : data is Map
                ? Map<String, Object?>.from(data)
                : {'data': data?.toString()},
          },
        );
      }
      final response = await dio.post(
        url,
        queryParameters: query,
        data: data,
        options: Options(
          validateStatus: (_) => true,
          contentType: isMultipart ? null : Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
      if (_isPaymentUrl(url)) {
        PaymentDebugLogger.info(
          'DioHelper.POST:response',
          data: {
            'url': url,
            'statusCode': response.statusCode,
            'response': _responseSnapshot(response),
          },
        );
      }
      return response;
    } catch (error) {
      if (_isPaymentUrl(url)) {
        PaymentDebugLogger.error(
          'DioHelper.POST:error',
          error: error,
          data: {'url': url, 'query': query, 'isMultipart': isMultipart},
        );
      }
      log('DioHelper (POST): $error');
      rethrow;
    }
  }

  /// Performs an asynchronous PUT request.
  ///
  /// Usually used for replacing a resource entirely.
  static Future<Response> putData({
    required String url,
    dynamic data,
    Map<String, dynamic>? query,
    String? token,
    bool isMultipart = false,
  }) async {
    try {
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        "Accept": "application/json",
        if (!isMultipart) "Content-Type": "application/json",
      };
      return await dio.put(
        url,
        data: data,
        queryParameters: query,
        options: Options(
          validateStatus: (_) => true,
          contentType: isMultipart ? null : Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
    } catch (error) {
      log('DioHelper (PUT): $error');
      rethrow;
    }
  }

  /// Performs an asynchronous PATCH request.
  ///
  /// Used for partial resource updates.
  static Future<Response> patchData({
    required String url,
    dynamic data,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    try {
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        "Accept": "application/json",
        "Content-Type": "application/json",
      };
      return await dio.patch(
        url,
        data: data,
        queryParameters: query,
        options: Options(
          validateStatus: (_) => true,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
    } catch (error) {
      log('DioHelper (PATCH): $error');
      rethrow;
    }
  }

  /// Performs an asynchronous DELETE request.
  static Future<Response> deleteData({
    required String url,
    Map<String, dynamic>? query,
    dynamic data,
    String? token,
  }) async {
    try {
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        "Accept": "application/json",
        "Content-Type": "application/json",
      };
      return await dio.delete(url, queryParameters: query, data: data);
    } catch (error) {
      log('DioHelper (DELETE): $error');
      rethrow;
    }
  }
}
