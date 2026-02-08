import 'package:turathy/src/core/helper/dio/end_points.dart';
import 'package:turathy/src/core/helper/socket/socket_exports.dart';
import 'package:turathy/src/features/home/domain/category_model.dart';

class AuctionModel {
  int? id;
  String? title;
  String? description;
  String? currentProduct;
  num? actualPrice;
  num? minBidPrice;
  num? quantity;
  num? bidPrice;
  String? expiryDate;
  String? startDate;
  bool? isLive;
  bool? isExpired;
  bool? isCanceled;
  String? imageUrl;
  int? userId;
  int? winningUserId;
  int? categoryId;
  String? createdAt;
  String? updatedAt;
  CategoryModel? category;
  User? user;
  List<AuctionProducts>? auctionProducts;
  List<SocketComment>? auctionComments;
  List<AuctionBid>? auctionBids;
  late bool isLiveAuction;
  List<String>? auctionImages;
  String? material;
  String? approximateAge;
  String? condition;
  String? origin;
  String? usage;

  String get type => isLiveAuction ? 'live' : 'public';

  AuctionModel({
    this.id,
    this.title,
    this.description,
    this.currentProduct,
    this.actualPrice,
    this.minBidPrice,
    this.quantity,
    this.bidPrice,
    this.expiryDate,
    this.startDate,
    this.isLive,
    this.isExpired,
    this.isCanceled,
    this.imageUrl,
    this.userId,
    this.winningUserId,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.user,
    this.auctionProducts,
    required this.isLiveAuction,
    this.auctionComments,
    this.auctionBids,
    this.auctionImages,
    this.material,
    this.approximateAge,
    this.condition,
    this.origin,
    this.usage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuctionModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          currentProduct == other.currentProduct &&
          actualPrice == other.actualPrice &&
          minBidPrice == other.minBidPrice &&
          quantity == other.quantity &&
          bidPrice == other.bidPrice &&
          expiryDate == other.expiryDate &&
          startDate == other.startDate &&
          isLive == other.isLive &&
          isExpired == other.isExpired &&
          isCanceled == other.isCanceled &&
          imageUrl == other.imageUrl &&
          userId == other.userId &&
          winningUserId == other.winningUserId &&
          categoryId == other.categoryId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          category == other.category &&
          user == other.user &&
          auctionProducts == other.auctionProducts &&
          isLiveAuction == other.isLiveAuction &&
          material == other.material &&
          approximateAge == other.approximateAge &&
          condition == other.condition &&
          origin == other.origin &&
          usage == other.usage;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      currentProduct.hashCode ^
      actualPrice.hashCode ^
      minBidPrice.hashCode ^
      quantity.hashCode ^
      bidPrice.hashCode ^
      expiryDate.hashCode ^
      startDate.hashCode ^
      isLive.hashCode ^
      isExpired.hashCode ^
      isCanceled.hashCode ^
      imageUrl.hashCode ^
      userId.hashCode ^
      winningUserId.hashCode ^
      categoryId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      category.hashCode ^
      user.hashCode ^
      auctionProducts.hashCode ^
      isLiveAuction.hashCode ^
      material.hashCode ^
      approximateAge.hashCode ^
      condition.hashCode ^
      origin.hashCode ^
      usage.hashCode;

  AuctionModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    currentProduct = json['current_product'];
    actualPrice = json['actualPrice'];
    minBidPrice = json['minBidPrice'];
    quantity = json['quantity'];
    bidPrice = json['bidPrice'];
    expiryDate = json['expiryDate'];
    startDate = json['startDate'];
    isLive = json['isLive'];
    isExpired = json['isExpired'];
    isCanceled = json['isCanceled'];
    imageUrl = json['image_url'] != null
        ? EndPoints.baseUrl + Uri.encodeFull(json['image_url'])
        : '';
    auctionImages = json['Auction_images'] != null
        ? List<String>.from(
            json['Auction_images'].map(
              (x) => EndPoints.baseUrl + Uri.encodeFull(x['image']),
            ),
          )
        : [];
    userId = json['user_id'];
    winningUserId = json['winning_user_id'];
    categoryId = json['category_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    category = json['category'] != null
        ? CategoryModel.fromJson(json['category'])
        : null;
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    if (json['auction_products'] != null) {
      auctionProducts = <AuctionProducts>[];
      json['auction_products'].forEach((v) {
        auctionProducts!.add(AuctionProducts.fromJson(v));
      });
    }

    if (json['Auction_comments'] != null) {
      auctionComments = <SocketComment>[];
      json['Auction_comments'].forEach((v) {
        auctionComments!.add(SocketComment.fromJson(v));
      });
    }

    if (json['Auction_bids'] != null) {
      auctionBids = <AuctionBid>[];
      json['Auction_bids'].forEach((v) {
        auctionBids!.add(AuctionBid.fromJson(v));
      });
    }
    isLiveAuction = json['type'] == 'Live';
    material = json['material'];
    approximateAge = json['approximateAge'];
    condition = json['condition'];
    origin = json['origin'];
    usage = json['usage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['current_product'] = currentProduct;
    data['actualPrice'] = actualPrice;
    data['minBidPrice'] = minBidPrice;
    data['quantity'] = quantity;
    data['bidPrice'] = bidPrice;
    data['expiryDate'] = expiryDate;
    data['startDate'] = startDate;
    data['isLive'] = isLive;
    data['isExpired'] = isExpired;
    data['isCanceled'] = isCanceled;
    data['image_url'] = imageUrl;
    data['user_id'] = userId;
    data['winning_user_id'] = winningUserId;
    data['category_id'] = categoryId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['material'] = material;
    data['approximateAge'] = approximateAge;
    data['condition'] = condition;
    data['origin'] = origin;
    data['usage'] = usage;
    if (category != null) {
      data['category'] = category!.toJson();
    }
    if (user != null) {
      data['user'] = user!.toJson();
    }
    if (auctionProducts != null) {
      data['auction_products'] = auctionProducts!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }

  @override
  String toString() {
    return 'AuctionModel{id: $id, title: $title, description: $description, currentProduct: $currentProduct, actualPrice: $actualPrice, minBidPrice: $minBidPrice, quantity: $quantity, bidPrice: $bidPrice, expiryDate: $expiryDate, startDate: $startDate, isLive: $isLive, isExpired: $isExpired, isCanceled: $isCanceled, imageUrl: $imageUrl, userId: $userId, winningUserId: $winningUserId, categoryId: $categoryId, createdAt: $createdAt, updatedAt: $updatedAt, category: $category, user: $user, auctionProducts: $auctionProducts, auctionComments: $auctionComments, auctionBids: $auctionBids, material: $material, approximateAge: $approximateAge, condition: $condition, origin: $origin, usage: $usage}';
  }
}

class User {
  int? id;
  String? name;
  String? number;
  String? password;
  String? otpCode;
  String? createdAt;
  String? updatedAt;

  User({
    this.id,
    this.name,
    this.number,
    this.password,
    this.otpCode,
    this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          number == other.number &&
          password == other.password &&
          otpCode == other.otpCode &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      number.hashCode ^
      password.hashCode ^
      otpCode.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    number = json['number'];
    password = json['password'];
    otpCode = json['otpCode'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['number'] = number;
    data['password'] = password;
    data['otpCode'] = otpCode;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}

class AuctionProducts {
  int? id;
  String? product;
  String? bidPrice;
  String? minBidPrice;
  String? actualPrice;
  int? auctionId;
  String? createdAt;
  String? updatedAt;
  String? imageUrl;

  AuctionProducts({
    this.id,
    this.product,
    this.bidPrice,
    this.minBidPrice,
    this.actualPrice,
    this.auctionId,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuctionProducts &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          product == other.product &&
          bidPrice == other.bidPrice &&
          minBidPrice == other.minBidPrice &&
          actualPrice == other.actualPrice &&
          auctionId == other.auctionId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      product.hashCode ^
      bidPrice.hashCode ^
      minBidPrice.hashCode ^
      actualPrice.hashCode ^
      auctionId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      imageUrl.hashCode;

  AuctionProducts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    product = json['product'];
    bidPrice = json['bidPrice'];
    minBidPrice = json['minBidPrice'];
    actualPrice = json['actualPrice'];
    auctionId = json['auction_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    imageUrl = json['image'] != null ? EndPoints.baseUrl + json['image'] : '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product'] = product;
    data['bidPrice'] = bidPrice;
    data['minBidPrice'] = minBidPrice;
    data['actualPrice'] = actualPrice;
    data['auction_id'] = auctionId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['image'] = imageUrl;
    return data;
  }
}

class AuctionBid {
  int? id;
  int? auctionId;
  int? userId;
  num? bid;
  String? createdAt;
  String? updatedAt;
  User? user;

  AuctionBid({
    this.id,
    this.auctionId,
    this.userId,
    this.bid,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  AuctionBid.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    auctionId = json['auction_id'];
    userId = json['user_id'];
    bid = json['bid'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['auction_id'] = auctionId;
    data['user_id'] = userId;
    data['bid'] = bid;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}
