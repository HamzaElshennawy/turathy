import 'package:turathy/src/features/auctions/domain/auction_model.dart';

class MaxBidModel {
  int? id;
  int? userId;
  int? auctionId;
  int? productId;
  num? maxAmount;
  String? createdAt;
  String? updatedAt;
  User? user;
  AuctionModel? auction;
  AuctionProducts? product;

  MaxBidModel({
    this.id,
    this.userId,
    this.auctionId,
    this.productId,
    this.maxAmount,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.auction,
    this.product,
  });

  MaxBidModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    auctionId = json['auction_id'];
    productId = json['product_id'];
    maxAmount = json['max_amount'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    auction = json['auction'] != null
        ? AuctionModel.fromJson(json['auction'])
        : null;
    product = json['product'] != null
        ? AuctionProducts.fromJson(json['product'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['auction_id'] = auctionId;
    data['product_id'] = productId;
    data['max_amount'] = maxAmount;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (auction != null) {
      data['auction'] = auction!.toJson();
    }
    if (product != null) {
      data['product'] = product!.toJson();
    }
    return data;
  }
}
