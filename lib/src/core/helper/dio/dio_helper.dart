import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../../features/authintication/data/auth_repository.dart';
import '../../../routing/app_router.dart';
import '../../../routing/rout_constants.dart';
import 'end_points.dart';

class DioHelper {
  static late Dio dio;

  static init() {
    dio = Dio(
      BaseOptions(
        baseUrl: EndPoints.baseUrl,
        receiveDataWhenStatusError: true,
        followRedirects: false,
        // will not throw errors
        validateStatus: (status) => true,
      ),
    );
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.statusCode == 401) {
            if (response.requestOptions.path == EndPoints.login ||
                response.requestOptions.path == EndPoints.userSignup) {
              return handler.next(response);
            }
            // using navigator
            goRouter.push(RouteConstants.signIn);
            AuthRepository.clearLocalDetails();
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            goRouter.push(RouteConstants.signIn);
            AuthRepository.clearLocalDetails();
          }
          return handler.next(error);
        },
      ),
    );
  }

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
      return await dio.get(
        url,
        queryParameters: query,
        options: Options(
          validateStatus: (_) => true,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
    } catch (error) {
      rethrow;
    }
  }

  static Future<Response> postData({
    required String url,
    Map<String, dynamic>? query,
    dynamic data,
    String lang = 'en',
    String? token,
  }) async {
    try {
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        "Accept": "application/json",
        "Content-Type": "application/json",
      };
      return await dio.post(
        url,
        queryParameters: query,
        data: data,
        options: Options(
          validateStatus: (_) => true,
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
    } catch (error) {
      rethrow;
    }
  }

  static Future<Response> putData({
    required String url,
    dynamic data,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    try {
      dio.options.headers = {'Authorization': 'Bearer $token'};
      Response response = await dio.put(
        url,
        data: data,
        queryParameters: query,
      );
      return response;
    } catch (error) {
      rethrow;
    }
  }

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
      rethrow;
    }
  }

  static Future<Response> deleteData({
    required String url,
    Map<String, dynamic>? query,
    dynamic data,
    String lang = 'en',
    String? token,
  }) async {
    try {
      dio.options.headers = {
        'Authorization': 'Bearer $token',
        "Accept": "application/json",
        "Content-Type": "application/json",
      };
      final response = await dio.delete(
        url,
        queryParameters: query,
        data: data,
      );

      return response;
    } catch (error) {
      rethrow;
    }
  }
}
