import 'order_model.dart';

enum OrderFlowStage {
  pending,
  paymentReview,
  paymentApprovedAwaitingOrderApproval,
  confirmed,
  shipped,
  delivered,
  cancelled,
  paymentRejected,
}

class OrderFlowState {
  OrderFlowState._();

  static String normalizedOrderStatus(OrderModel order) =>
      order.orderStatus?.toLowerCase() ?? 'pending';

  static String? normalizedPaymentStatus(OrderModel order) =>
      order.paymentStatus?.toLowerCase();

  static bool hasApprovedPayment(OrderModel order) =>
      ['approved', 'paid', 'captured', 'verified'].contains(
        normalizedPaymentStatus(order),
      );

  static bool isPaymentUnderReview(OrderModel order) =>
      normalizedPaymentStatus(order) == 'initiated';

  static OrderFlowStage stage(OrderModel order) {
    final orderStatus = normalizedOrderStatus(order);
    final paymentStatus = normalizedPaymentStatus(order);

    switch (orderStatus) {
      case 'confirmed':
        return OrderFlowStage.confirmed;
      case 'shipped':
        return OrderFlowStage.shipped;
      case 'delivered':
        return OrderFlowStage.delivered;
      case 'cancelled':
        return OrderFlowStage.cancelled;
    }

    if (paymentStatus == 'rejected' || paymentStatus == 'failed') {
      return OrderFlowStage.paymentRejected;
    }

    if (isPaymentUnderReview(order) || orderStatus == 'pending_approval') {
      return OrderFlowStage.paymentReview;
    }

    if (hasApprovedPayment(order)) {
      return OrderFlowStage.paymentApprovedAwaitingOrderApproval;
    }

    return OrderFlowStage.pending;
  }

  static bool canEditAddress(OrderModel order) =>
      stage(order) == OrderFlowStage.pending;

  static bool canUploadReceipt(OrderModel order) {
    final currentStage = stage(order);
    return currentStage == OrderFlowStage.pending ||
        currentStage == OrderFlowStage.paymentRejected;
  }

  static bool canOpenOrderFromAuction(OrderModel order) {
    final currentStage = stage(order);
    return currentStage == OrderFlowStage.paymentReview ||
        currentStage == OrderFlowStage.paymentApprovedAwaitingOrderApproval ||
        currentStage == OrderFlowStage.confirmed ||
        currentStage == OrderFlowStage.shipped ||
        currentStage == OrderFlowStage.delivered;
  }
}
