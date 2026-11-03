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
    final product = json['product'];
    final winning = json['winning'];
    final auction = winning is Map ? winning['auction'] : null;
    return AuctionPaymentModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      winningId: _asInt(json['winning_id']),
      productId: _asInt(json['product_id']),
      receiptUrl: _text(json['receipt_url']) ?? '',
      amount: _asInt(json['amount']),
      status: _text(json['status']) ?? 'pending',
      adminNotes: _text(json['admin_notes']),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())?.toLocal()
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      productName: _firstText([
        product is Map ? product['product'] : null,
        product is Map ? product['product_ar'] : null,
        product is Map ? product['product_en'] : null,
      ]),
      auctionTitle: _firstText([
        auction is Map ? auction['title'] : null,
        auction is Map ? auction['title_ar'] : null,
        auction is Map ? auction['title_en'] : null,
      ]),
    );
  }

  bool get hasReceipt => receiptUrl.trim().isNotEmpty;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isUnpaid => status == 'unpaid';

  String get fullReceiptUrl {
    if (receiptUrl.startsWith('http')) return receiptUrl;
    return '${EndPoints.baseUrl}$receiptUrl';
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _text(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _firstText(List<dynamic> values) {
  for (final value in values) {
    final text = _text(value);
    if (text != null) return text;
  }
  return null;
}
