import 'package:easy_localization/easy_localization.dart';

class WinningAuctionModel {
  final int id;
  final int userId;
  final int auctionId;
  final String product;
  final double price;
  final bool sold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String auctionTitle;
  final DateTime auctionStartDate;
  final String winnerName;

  const WinningAuctionModel({
    required this.id,
    required this.userId,
    required this.auctionId,
    required this.product,
    required this.price,
    required this.sold,
    required this.createdAt,
    required this.updatedAt,
    required this.auctionTitle,
    required this.auctionStartDate,
    required this.winnerName,
  });

  // equal operator for all fields
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WinningAuctionModel) return false;
    return id == other.id &&
        userId == other.userId &&
        auctionId == other.auctionId &&
        product == other.product &&
        price == other.price &&
        sold == other.sold &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        auctionTitle == other.auctionTitle &&
        auctionStartDate == other.auctionStartDate &&
        winnerName == other.winnerName;
  }

  // hash code for all fields
  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      auctionId.hashCode ^
      product.hashCode ^
      price.hashCode ^
      sold.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      auctionTitle.hashCode ^
      auctionStartDate.hashCode ^
      winnerName.hashCode;

  factory WinningAuctionModel.fromJson(Map<String, dynamic> json) {
    return WinningAuctionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      auctionId: json['auction_id'] as int,
      product: json['product'] as String,
      price: (json['price'] as num).toDouble(),
      sold: json['sold'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      auctionTitle: json['auction']['title'] as String,
      auctionStartDate: DateTime.parse(
        json['auction']['startDate'] as String,
      ).toLocal(),
      winnerName: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'auction_id': auctionId,
      'product': product,
      'price': price,
      'sold': sold,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'auction': {
        'title': auctionTitle,
        'startDate': auctionStartDate.toIso8601String(),
      },
      'name': winnerName,
    };
  }

  String get formattedPrice =>
      NumberFormat.currency(symbol: 'SAR ', decimalDigits: 2).format(price);

  String get formattedCreatedAt =>
      DateFormat('dd/MM/yyyy hh:mm a').format(createdAt);

  String get formattedStartDate =>
      DateFormat('dd/MM/yyyy hh:mm a').format(auctionStartDate);
}
