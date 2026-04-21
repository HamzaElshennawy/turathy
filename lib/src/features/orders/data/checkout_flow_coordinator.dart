import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../auctions/data/auction_payments_repository.dart';
import '../domain/geidea_checkout_session_model.dart';
import '../domain/order_model.dart';
import '../domain/saved_payment_method_model.dart';
import '../utils/payment_debug_logger.dart';
import 'order_repository.dart';
import 'payments_repository.dart';

class CheckoutFlowCoordinator {
  CheckoutFlowCoordinator({
    required OrderRepository orderRepository,
    required AuctionPaymentsRepository auctionPaymentsRepository,
    required PaymentsRepository paymentsRepository,
  }) : _orderRepository = orderRepository,
       _auctionPaymentsRepository = auctionPaymentsRepository,
       _paymentsRepository = paymentsRepository;

  final OrderRepository _orderRepository;
  final AuctionPaymentsRepository _auctionPaymentsRepository;
  final PaymentsRepository _paymentsRepository;

  Future<OrderModel> syncOrderDetails({
    required OrderModel order,
    required int addressId,
  }) async {
    PaymentDebugLogger.info('syncOrderDetails:start', data: {
      'orderId': order.id,
      'userId': order.userId,
      'addressId': addressId,
      'isNewOrder': order.id == 0,
      'auctionId': order.auctionId,
    });
    final updatedOrderData = order.copyWith(addressId: addressId);

    if (order.id == 0) {
      final created = await _orderRepository.createOrder(updatedOrderData);
      PaymentDebugLogger.info('syncOrderDetails:created', data: {
        'orderId': created.id,
        'paymentStatus': created.paymentStatus,
        'orderStatus': created.orderStatus,
      });
      return created;
    }

    final updated = await _orderRepository.updateOrder(updatedOrderData);
    PaymentDebugLogger.info('syncOrderDetails:updated', data: {
      'orderId': updated.id,
      'paymentStatus': updated.paymentStatus,
      'orderStatus': updated.orderStatus,
    });
    return updated;
  }

  Future<OrderModel> submitBankTransfer({
    required OrderModel order,
    required String filePath,
  }) async {
    PaymentDebugLogger.info('submitBankTransfer:start', data: {
      'orderId': order.id,
      'auctionId': order.auctionId,
      'filePath': filePath,
      'amount': order.total.toInt(),
    });
    if (order.auctionId != 0) {
      await _auctionPaymentsRepository.uploadReceipt(
        userId: order.userId,
        auctionId: order.auctionId,
        productId:
            (order.items.firstOrNull?.auctionProductId ??
                order.items.firstOrNull?.productId) ??
            0,
        orderId: order.id,
        amount: order.total.toInt(),
        filePath: filePath,
      );

      final trusted = await _orderRepository.getTrustedOrderStatus(order.id);
      PaymentDebugLogger.info('submitBankTransfer:auction:trustedStatus', data: {
        'orderId': trusted.id,
        'paymentStatus': trusted.paymentStatus,
        'orderStatus': trusted.orderStatus,
      });
      return trusted;
    }

    await _orderRepository.uploadStoreReceipt(
      userId: order.userId,
      orderId: order.id,
      amount: order.total.toInt(),
      filePath: filePath,
    );

    final trusted = await _orderRepository.getTrustedOrderStatus(order.id);
    PaymentDebugLogger.info('submitBankTransfer:store:trustedStatus', data: {
      'orderId': trusted.id,
      'paymentStatus': trusted.paymentStatus,
      'orderStatus': trusted.orderStatus,
    });
    return trusted;
  }

  Future<GeideaCheckoutSessionModel> createGeideaCheckoutSession({
    required OrderModel order,
    bool cardOnFile = false,
    int? savedMethodId,
  }) {
    PaymentDebugLogger.info('createGeideaCheckoutSession:start', data: {
      'orderId': order.id,
      'userId': order.userId,
      'cardOnFile': cardOnFile,
      'savedMethodId': savedMethodId,
    });
    return _paymentsRepository.createGeideaSession(
      orderId: order.id,
      cardOnFile: cardOnFile,
      savedMethodId: savedMethodId,
      language: Intl.getCurrentLocale().toLowerCase().startsWith('ar') ? 'ar' : 'en',
    );
  }

  Future<GeideaCheckoutSessionModel> createGeideaSaveCardSession({
    required int userId,
  }) {
    PaymentDebugLogger.info('createGeideaSaveCardSession:start', data: {
      'userId': userId,
    });
    return _paymentsRepository.createGeideaSaveCardSession(
      language: Intl.getCurrentLocale().toLowerCase().startsWith('ar')
          ? 'ar'
          : 'en',
    );
  }

  Future<List<SavedPaymentMethodModel>> getSavedPaymentMethods({
    required int userId,
  }) {
    PaymentDebugLogger.info('getSavedPaymentMethods:start', data: {
      'userId': userId,
    });
    return _paymentsRepository.listSavedPaymentMethods(userId: userId);
  }

  Future<SavedPaymentMethodModel> deactivateSavedPaymentMethod({
    required int userId,
    required int methodId,
  }) {
    PaymentDebugLogger.info('deactivateSavedPaymentMethod:start', data: {
      'userId': userId,
      'methodId': methodId,
    });
    return _paymentsRepository.deactivateSavedPaymentMethod(
      userId: userId,
      methodId: methodId,
    );
  }

  Future<SavedPaymentMethodModel> setDefaultSavedPaymentMethod({
    required int userId,
    required int methodId,
  }) {
    PaymentDebugLogger.info('setDefaultSavedPaymentMethod:start', data: {
      'userId': userId,
      'methodId': methodId,
    });
    return _paymentsRepository.setDefaultSavedPaymentMethod(
      userId: userId,
      methodId: methodId,
    );
  }
}

final checkoutFlowCoordinatorProvider = Provider<CheckoutFlowCoordinator>((ref) {
  return CheckoutFlowCoordinator(
    orderRepository: ref.watch(orderRepositoryProvider),
    auctionPaymentsRepository: ref.watch(auctionPaymentsRepositoryProvider),
    paymentsRepository: ref.watch(paymentsRepositoryProvider),
  );
});
