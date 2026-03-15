/// Unified socket event models to avoid duplication across the app
library;

import 'package:turathy/src/features/auctions/domain/auction_model.dart';

/// User count update event from socket
class UserCountUpdate {
  final int auctionId;
  final int userCount;

  const UserCountUpdate({required this.auctionId, required this.userCount});

  factory UserCountUpdate.fromJson(Map<String, dynamic> json) {
    return UserCountUpdate(
      auctionId: json['auctionId'] as int,
      userCount: json['userCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'auctionId': auctionId, 'userCount': userCount};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCountUpdate &&
          runtimeType == other.runtimeType &&
          auctionId == other.auctionId &&
          userCount == other.userCount;

  @override
  int get hashCode => auctionId.hashCode ^ userCount.hashCode;

  @override
  String toString() =>
      'UserCountUpdate(auctionId: $auctionId, userCount: $userCount)';
}

/// Single comment model for socket events
class SocketComment {
  final int id;
  final int auctionId;
  final int userId;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SocketUser user;

  const SocketComment({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory SocketComment.fromJson(Map<String, dynamic> json) {
    return SocketComment(
      id: json['id'] as int,
      auctionId: json['auction_id'] as int,
      userId: json['user_id'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: SocketUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'user_id': userId,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'user': user.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocketComment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          auctionId == other.auctionId &&
          userId == other.userId &&
          comment == other.comment &&
          user == other.user;

  @override
  int get hashCode =>
      id.hashCode ^
      auctionId.hashCode ^
      userId.hashCode ^
      comment.hashCode ^
      user.hashCode;

  @override
  String toString() =>
      'SocketComment(id: $id, auctionId: $auctionId, comment: $comment)';
}

/// Comment event containing new comment and all comments
class CommentEvent {
  final SocketComment newComment;
  final List<SocketComment> allComments;

  const CommentEvent({required this.newComment, required this.allComments});

  factory CommentEvent.fromJson(Map<String, dynamic> json) {
    return CommentEvent(
      newComment: SocketComment.fromJson(
        json['newComment'] as Map<String, dynamic>,
      ),
      allComments: (json['comments'] as List<dynamic>)
          .map(
            (comment) =>
                SocketComment.fromJson(comment as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newComment': newComment.toJson(),
      'comments': allComments.map((comment) => comment.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentEvent &&
          runtimeType == other.runtimeType &&
          newComment == other.newComment;

  @override
  int get hashCode => newComment.hashCode;

  @override
  String toString() =>
      'CommentEvent(newComment: $newComment, totalComments: ${allComments.length})';
}

/// User model for socket events
class SocketUser {
  final int id;
  final String name;
  final String? nickname;
  final String? nationality;
  final String number;

  const SocketUser({
    required this.id,
    required this.name,
    this.nickname,
    this.nationality,
    required this.number,
  });

  factory SocketUser.fromJson(Map<String, dynamic> json) {
    return SocketUser(
      id: json['id'] as int,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      nationality: json['nationality'] as String?,
      number: json['number'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'nationality': nationality,
      'number': number,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocketUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          nickname == other.nickname &&
          nationality == other.nationality &&
          number == other.number;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      nickname.hashCode ^
      nationality.hashCode ^
      number.hashCode;

  String get displayTitle {
    final title = nickname ?? name;
    if (nationality != null && nationality!.isNotEmpty) {
      return '$title ${getFlagEmoji(nationality!)}';
    }
    return title;
  }

  static String getFlagEmoji(String countryCode) {
    try {
      String code = countryCode.toUpperCase();
      if (code == 'EGY') code = 'EG';
      if (code == 'SAU') code = 'SA';
      if (code.length != 2) return code;

      int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
      int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
      return String.fromCharCode(firstLetter) +
          String.fromCharCode(secondLetter);
    } catch (e) {
      return countryCode;
    }
  }

  @override
  String toString() => 'SocketUser(id: $id, name: $name, nickname: $nickname)';
}

/// Auction product change event model
class AuctionProductChangeEvent {
  final String product;
  final num bidPrice;
  final num minBidPrice;
  final num actualPrice;

  const AuctionProductChangeEvent({
    required this.product,
    required this.bidPrice,
    required this.minBidPrice,
    required this.actualPrice,
  });

  factory AuctionProductChangeEvent.fromJson(Map<String, dynamic> json) {
    return AuctionProductChangeEvent(
      product: json['product'] as String,
      bidPrice: json['bidPrice'] as num,
      minBidPrice: json['minBidPrice'] as num,
      actualPrice: json['actualPrice'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'bidPrice': bidPrice,
      'minBidPrice': minBidPrice,
      'actualPrice': actualPrice,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuctionProductChangeEvent &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          bidPrice == other.bidPrice &&
          minBidPrice == other.minBidPrice &&
          actualPrice == other.actualPrice;

  @override
  int get hashCode =>
      product.hashCode ^
      bidPrice.hashCode ^
      minBidPrice.hashCode ^
      actualPrice.hashCode;

  @override
  String toString() =>
      'AuctionProductChangeEvent(product: $product, bidPrice: $bidPrice)';
}

/// Socket error event model
class SocketErrorEvent {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const SocketErrorEvent({required this.message, this.code, this.details});

  factory SocketErrorEvent.fromJson(Map<String, dynamic> json) {
    return SocketErrorEvent(
      message: json['message'] as String,
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (code != null) 'code': code,
      if (details != null) 'details': details,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocketErrorEvent &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => 'SocketErrorEvent(message: $message, code: $code)';
}

/// Auction ended event model
class AuctionEndedEvent {
  final SocketUser? winningUser;
  final int auctionId;
  final AuctionModel? auction;
  final num? finalBidAmount;
  final int? seq;

  String get winnerName => winningUser?.displayTitle ?? 'Unknown';
  int? get winnerId => winningUser?.id;

  const AuctionEndedEvent({
    this.winningUser,
    required this.auctionId,
    this.auction,
    this.finalBidAmount,
    this.seq,
  });

  factory AuctionEndedEvent.fromJson(Map<String, dynamic> json) {
    return AuctionEndedEvent(
      winningUser: json['winningUser'] != null
          ? SocketUser.fromJson(json['winningUser'] as Map<String, dynamic>)
          : null,
      auctionId: json['auctionId'] as int? ?? 0,
      auction: json['auction'] != null
          ? AuctionModel.fromJson(json['auction'] as Map<String, dynamic>)
          : null,
      finalBidAmount: json['finalBidAmount'] as num?,
      seq: json['seq'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'winningUser': winningUser?.toJson(),
      'auctionId': auctionId,
      'auction': auction?.toJson(),
      if (finalBidAmount != null) 'finalBidAmount': finalBidAmount,
      if (seq != null) 'seq': seq,
    };
  }

  @override
  String toString() =>
      'AuctionEndedEvent(winner: ${winningUser?.name}, auctionId: $auctionId, seq: $seq)';
}

/// Bid placed event model
class BidPlacedEvent {
  final AuctionBid newBid;
  final List<AuctionBid> auctionBids;
  final num? currentPrice;
  final DateTime? expiryDate;
  final int? seq;

  const BidPlacedEvent({
    required this.newBid,
    required this.auctionBids,
    this.currentPrice,
    this.expiryDate,
    this.seq,
  });

  factory BidPlacedEvent.fromJson(Map<String, dynamic> json) {
    return BidPlacedEvent(
      newBid: AuctionBid.fromJson(json['newBid'] as Map<String, dynamic>),
      auctionBids:
          (json['auctionBids'] as List<dynamic>?)
              ?.map((e) => AuctionBid.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentPrice: json['currentPrice'] as num?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      seq: json['seq'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newBid': newBid.toJson(),
      'auctionBids': auctionBids.map((e) => e.toJson()).toList(),
      'currentPrice': currentPrice,
      'expiryDate': expiryDate?.toIso8601String(),
      if (seq != null) 'seq': seq,
    };
  }

  @override
  String toString() =>
      'BidPlacedEvent(newBid: ${newBid.bid}, expiryDate: $expiryDate, seq: $seq)';
}

/// Auction item ended event model (for multi-item auctions)
class AuctionItemEndedEvent {
  final AuctionModel auction;
  final AuctionProducts? nextItem;
  final SocketUser? winner;
  final int? seq;

  const AuctionItemEndedEvent({
    required this.auction,
    this.nextItem,
    this.winner,
    this.seq,
  });

  factory AuctionItemEndedEvent.fromJson(Map<String, dynamic> json) {
    return AuctionItemEndedEvent(
      auction: AuctionModel.fromJson(json['auction'] as Map<String, dynamic>),
      nextItem: json['nextItem'] != null
          ? AuctionProducts.fromJson(json['nextItem'] as Map<String, dynamic>)
          : null,
      winner: json['winner'] != null
          ? SocketUser.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
      seq: json['seq'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auction': auction.toJson(),
      'nextItem': nextItem?.toJson(),
      'winner': winner?.toJson(),
      if (seq != null) 'seq': seq,
    };
  }

  @override
  String toString() =>
      'AuctionItemEndedEvent(auctionId: ${auction.id}, nextItem: ${nextItem?.displayName}, winner: ${winner?.name}, seq: $seq)';
}

/// Bid rejected event — emitted when the server rejects a bid due to a stale price.
/// Contains the server's authoritative current price so the client can self-heal.
class BidRejectedEvent {
  final String message;
  final num? currentPrice;
  final num? minimumBid;
  final int? productId;

  const BidRejectedEvent({
    required this.message,
    this.currentPrice,
    this.minimumBid,
    this.productId,
  });

  factory BidRejectedEvent.fromJson(Map<String, dynamic> json) {
    return BidRejectedEvent(
      message: (json['message'] as String?) ?? '',
      currentPrice: json['currentPrice'] as num?,
      minimumBid: json['minimumBid'] as num?,
      productId: json['productId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (currentPrice != null) 'currentPrice': currentPrice,
      if (minimumBid != null) 'minimumBid': minimumBid,
      if (productId != null) 'productId': productId,
    };
  }

  @override
  String toString() =>
      'BidRejectedEvent(currentPrice: $currentPrice, minimumBid: $minimumBid)';
}

/// Auction State Update event — emitted blindly by the server every 2 seconds.
/// Contains the absolute source of truth for the auction timer and every product
/// with its top 3 bids, requiring zero client-side logic to stay in sync.
class AuctionStateUpdateEvent {
  final int auctionId;
  final DateTime? expiryDate;
  final int? currentProductId;
  final List<StateUpdateProduct> products;
  final int? seq;

  const AuctionStateUpdateEvent({
    required this.auctionId,
    this.expiryDate,
    this.currentProductId,
    required this.products,
    this.seq,
  });

  factory AuctionStateUpdateEvent.fromJson(Map<String, dynamic> json) {
    return AuctionStateUpdateEvent(
      auctionId: json['auctionId'] as int,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      currentProductId: json['currentProductId'] as int?,
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => StateUpdateProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      seq: json['seq'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auctionId': auctionId,
      'expiryDate': expiryDate?.toIso8601String(),
      'currentProductId': currentProductId,
      'products': products.map((e) => e.toJson()).toList(),
      if (seq != null) 'seq': seq,
    };
  }

  @override
  String toString() =>
      'AuctionStateUpdateEvent(auctionId: $auctionId, expiryDate: $expiryDate, products: ${products.length})';
}

/// A lightweight product snapshot included in every state broadcast.
/// Contains the full product fields plus the top 3 bids from the server cache.
class StateUpdateProduct {
  final int? id;
  final String? productAr;
  final String? productEn;
  final String? bidPrice;
  final String? minBidPrice;
  final String? actualPrice;
  final int? auctionId;
  final List<AuctionBid> topBids;

  const StateUpdateProduct({
    this.id,
    this.productAr,
    this.productEn,
    this.bidPrice,
    this.minBidPrice,
    this.actualPrice,
    this.auctionId,
    required this.topBids,
  });

  factory StateUpdateProduct.fromJson(Map<String, dynamic> json) {
    return StateUpdateProduct(
      id: json['id'] as int?,
      productAr: json['product_ar'] as String? ?? json['product'] as String?,
      productEn: json['product_en'] as String?,
      bidPrice: json['bidPrice']?.toString(),
      minBidPrice: json['minBidPrice']?.toString(),
      actualPrice: json['actualPrice']?.toString(),
      auctionId: json['auction_id'] as int?,
      topBids: (json['topBids'] as List<dynamic>?)
              ?.map((e) => AuctionBid.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_ar': productAr,
      'product_en': productEn,
      'bidPrice': bidPrice,
      'minBidPrice': minBidPrice,
      'actualPrice': actualPrice,
      'auction_id': auctionId,
      'topBids': topBids.map((e) => e.toJson()).toList(),
    };
  }
}
