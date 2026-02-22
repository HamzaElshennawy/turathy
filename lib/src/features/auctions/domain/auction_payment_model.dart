import '../../../core/helper/dio/end_points.dart';

class AuctionPaymentModel {
  final int id;
  final int userId;
  final int winningId;
  final int productId;
  final String receiptUrl;
  final int amount;
  final String status; // pending, approved, rejected
  final String? adminNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? productName;
  final String? auctionTitle;

  const AuctionPaymentModel({
    required this.id,
    required this.userId,
    required this.winningId,
    required this.productId,
    required this.receiptUrl,
    required this.amount,
    required this.status,
    this.adminNotes,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.auctionTitle,
  });

  factory AuctionPaymentModel.fromJson(Map<String, dynamic> json) {
    return AuctionPaymentModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      winningId: json['winning_id'] as int,
      productId: json['product_id'] as int,
      receiptUrl: json['receipt_url'] as String,
      amount: json['amount'] as int,
      status: json['status'] as String,
      adminNotes: json['admin_notes'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      productName: json['product'] != null
          ? json['product']['product'] as String?
          : null,
      auctionTitle:
          json['winning'] != null && json['winning']['auction'] != null
          ? json['winning']['auction']['title'] as String?
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get fullReceiptUrl {
    if (receiptUrl.startsWith('http')) return receiptUrl;
    return '${EndPoints.baseUrl}$receiptUrl';
  }
}
