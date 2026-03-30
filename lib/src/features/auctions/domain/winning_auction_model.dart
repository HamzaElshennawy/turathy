import 'package:easy_localization/easy_localization.dart';

class WinningAuctionModel {
  final int id;
  final int userId;
  final int auctionId;
  final String product;
  final int? productId;
  final double price;
  final bool sold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String auctionTitle;
  final String? auctionTitleAr;
  final String? auctionTitleEn;
  final String? auctionDescriptionAr;
  final String? auctionDescriptionEn;
  final String? auctionImage;
  final DateTime auctionStartDate;
  final String winnerName;

  const WinningAuctionModel({
    required this.id,
    required this.userId,
    required this.auctionId,
    required this.product,
    this.productId,
    required this.price,
    required this.sold,
    required this.createdAt,
    required this.updatedAt,
    required this.auctionTitle,
    this.auctionTitleAr,
    this.auctionTitleEn,
    this.auctionDescriptionAr,
    this.auctionDescriptionEn,
    this.auctionImage,
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
        productId == other.productId &&
        price == other.price &&
        sold == other.sold &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        auctionTitle == other.auctionTitle &&
        auctionTitleAr == other.auctionTitleAr &&
        auctionTitleEn == other.auctionTitleEn &&
        auctionDescriptionAr == other.auctionDescriptionAr &&
        auctionDescriptionEn == other.auctionDescriptionEn &&
        auctionImage == other.auctionImage &&
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
      productId.hashCode ^
      price.hashCode ^
      sold.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      auctionTitle.hashCode ^
      auctionTitleAr.hashCode ^
      auctionTitleEn.hashCode ^
      auctionDescriptionAr.hashCode ^
      auctionDescriptionEn.hashCode ^
      auctionImage.hashCode ^
      auctionStartDate.hashCode ^
      winnerName.hashCode;

  factory WinningAuctionModel.fromJson(Map<String, dynamic> json) {
    return WinningAuctionModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      auctionId: int.tryParse(json['auction_id']?.toString() ?? '') ?? 0,
      product: json['product'] as String,
      productId: json['product_id'] != null ? int.tryParse(json['product_id'].toString()) : null,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      sold: json['sold'] == true || json['sold']?.toString() == 'true' || json['sold'] == 1,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      auctionTitle:
          (json['auction']['title_ar'] ??
                  json['auction']['title_en'] ??
                  json['auction']['title'] ??
                  '')
              as String,
      auctionTitleAr: json['auction']['title_ar'] as String?,
      auctionTitleEn: json['auction']['title_en'] as String?,
      auctionDescriptionAr: json['auction']['description_ar'] as String?,
      auctionDescriptionEn: json['auction']['description_en'] as String?,
      auctionImage:
          json['auction']['image_url'] as String? ??
          json['auction']['main_image'] as String?,
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
      'product_id': productId,
      'price': price,
      'sold': sold,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'auction': {
        'title': auctionTitle,
        'title_ar': auctionTitleAr,
        'title_en': auctionTitleEn,
        'description_ar': auctionDescriptionAr,
        'description_en': auctionDescriptionEn,
        'image_url': auctionImage,
        'startDate': auctionStartDate.toIso8601String(),
      },
      'name': winnerName,
    };
  }

  String localizedAuctionTitle(String locale) {
    return locale == 'ar'
        ? (auctionTitleAr ?? auctionTitle)
        : (auctionTitleEn ?? auctionTitle);
  }

  String localizedAuctionDescription(String locale) {
    return locale == 'ar'
        ? (auctionDescriptionAr ?? '')
        : (auctionDescriptionEn ?? '');
  }

  String get formattedPrice =>
      NumberFormat.currency(symbol: 'SAR ', decimalDigits: 2).format(price);

  String get formattedCreatedAt =>
      DateFormat('dd/MM/yyyy hh:mm a').format(createdAt);

  String get formattedStartDate =>
      DateFormat('dd/MM/yyyy hh:mm a').format(auctionStartDate);
}
