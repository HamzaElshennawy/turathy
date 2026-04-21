import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/cache/cached_variables.dart';
import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';
import '../../authintication/data/auth_repository.dart';
import '../domain/auction_payment_model.dart';
import '../../orders/utils/payment_debug_logger.dart';

class AuctionPaymentsRepository {
  Future<AuctionPaymentModel> uploadReceipt({
    required int userId,
    required int auctionId,
    required int productId,
    required int orderId,
    required int amount,
    required String filePath,
  }) async {
    final String fileName = filePath.split('/').last.split('\\').last;
    PaymentDebugLogger.info('uploadAuctionReceipt:request', data: {
      'userId': userId,
      'auctionId': auctionId,
      'productId': productId,
      'orderId': orderId,
      'amount': amount,
      'fileName': fileName,
      'filePath': filePath,
    });

    final formData = FormData.fromMap({
      'auction_id': auctionId,
      'product_id': productId,
      'order_id': orderId,
      'amount': amount,
      'receipt': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await DioHelper.postData(
      url: EndPoints.uploadReceipt,
      data: formData,
      token: CachedVariables.token,
      isMultipart: true,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      PaymentDebugLogger.info('uploadAuctionReceipt:success', data: {
        'statusCode': response.statusCode,
        'response': response.data is Map
            ? Map<String, Object?>.from(response.data as Map)
            : {'response': response.data.toString()},
      });
      return AuctionPaymentModel.fromJson(response.data['data']);
    } else {
      String message =
          response.data['error'] ?? 'An error occurred while uploading receipt';
      PaymentDebugLogger.error(
        'uploadAuctionReceipt:failure',
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
  }

  Future<List<AuctionPaymentModel>> getMyPayments() async {
    final response = await DioHelper.getData(
      url: EndPoints.myPayments,
      token: CachedVariables.token,
    );

    if (response.statusCode == 200) {
      final List<AuctionPaymentModel> payments = [];
      for (var item in response.data['data']) {
        payments.add(AuctionPaymentModel.fromJson(item));
      }
      return payments;
    } else {
      String message =
          response.data['error'] ?? 'An error occurred while fetching payments';
      throw AuthException(message, response.statusCode);
    }
  }
}

final auctionPaymentsRepositoryProvider = Provider<AuctionPaymentsRepository>((
  ref,
) {
  return AuctionPaymentsRepository();
});

final myPaymentsProvider =
    FutureProvider.autoDispose<List<AuctionPaymentModel>>((ref) async {
      return ref.watch(auctionPaymentsRepositoryProvider).getMyPayments();
    });
