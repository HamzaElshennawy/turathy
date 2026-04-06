/// {@category Core}
///
/// Unified data models for parsing and representing WebSocket event payloads.
/// 
/// These models are specifically designed to match the shape of the server-side 
/// WebSocket emitters used for real-time auction updates, which often differ 
/// from standard REST API response shapes (e.g., using different key naming 
/// or data types).
library;

import 'package:turathy/src/features/auctions/domain/auction_model.dart';

/// Payload for the 'userCountUpdate' event.
/// 
/// Informs the UI how many users are currently 'active' in a specific auction room.
class UserCountUpdate {
  /// The ID of the auction being viewed.
  final int auctionId;
  
  /// The total number of connected users in this auction's namespace.
  final int userCount;

  /// Default constructor for count updates.
  const UserCountUpdate({required this.auctionId, required this.userCount});

  /// Decodes server counts from [json].
  factory UserCountUpdate.fromJson(Map<String, dynamic> json) {
    return UserCountUpdate(
      auctionId: json['auctionId'] as int,
      userCount: json['userCount'] as int,
    );
  }

  /// Encodes count update to [Map].
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

/// Represents a single chat or system message within the auction room.
class SocketComment {
  /// Unique identifier for the comment.
  final int id;
  
  /// The ID of the auction where this comment was posted.
  /// 
  /// **Payload Key:** `auction_id` (snake_case).
  final int auctionId;
  
  /// The ID of the user who posted the comment.
  /// 
  /// **Payload Key:** `user_id` (snake_case).
  final int userId;
  
  /// The textual content of the message.
  final String comment;
  
  /// Timestamp indicating when the comment was first created.
  final DateTime createdAt;
  
  /// Timestamp indicating the last modification.
  final DateTime updatedAt;
  
  /// Detailed info about the sender, used for avatar and flag display.
  final SocketUser user;

  /// Default constructor for socket-based comments.
  const SocketComment({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  /// Parses a comment from a server JSON payload.
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

  /// Exports the comment to a format suitable for network transmission.
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

/// Payload for the 'newComment' event.
/// 
/// Includes the [newComment] and an updated list of [allComments] for the session,
/// ensuring the client stays in sync with the full message history.
class CommentEvent {
  /// The specific individual comment that triggered the reactive event.
  final SocketComment newComment;
  
  /// The complete rolling history of comments for the current room.
  final List<SocketComment> allComments;

  /// Default constructor for combined comment event payloads.
  const CommentEvent({required this.newComment, required this.allComments});

  /// Factory for parsing combined comment events from the server broadcast.
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

  /// Exports the event and its collection to JSON.
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

/// A simplified user model optimized for high-frequency WebSocket broadcasts.
/// 
/// Contains essential identity data required to display user names in chat 
/// and bid logs without the overhead of a full profile model.
class SocketUser {
  /// Database identifier for the user.
  final int id;
  
  /// Direct full name of the user.
  final String name;
  
  /// User-defined pseudonym or "handle" used during auctions.
  final String? nickname;
  
  /// ISO country code (e.g., 'SAU', 'EGY') used for flag decoration.
  final String? nationality;
  
  /// Contact phone number used for winner identification.
  final String number;

  /// Default constructor for socket-based user representations.
  const SocketUser({
    required this.id,
    required this.name,
    this.nickname,
    this.nationality,
    required this.number,
  });

  /// Parses specialized socket user data from JSON.
  factory SocketUser.fromJson(Map<String, dynamic> json) {
    return SocketUser(
      id: json['id'] as int,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      nationality: json['nationality'] as String?,
      number: json['number'] as String,
    );
  }

  /// Exports simplified user metadata to JSON.
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

  /// Returns the name or nickname decorated with a regional flag emoji.
  /// 
  /// Order of precedence: `nickname` > `name`.
  /// Uses [getFlagEmoji] to resolve codes to Unicode characters.
  String get displayTitle {
    final title = nickname ?? name;
    if (nationality != null && nationality!.isNotEmpty) {
      return '$title ${getFlagEmoji(nationality!)}';
    }
    return title;
  }

  /// Converts ISO country codes into Unicode flag emojis.
  /// 
  /// Supports both 2-letter (SA, EG) and common 3-letter (SAU, EGY) codes
  /// used across the platform.
  static String getFlagEmoji(String countryCode) {
    try {
      String code = countryCode.toUpperCase();
      // Standardization: Handle 3-letter code mapping
      if (code == 'EGY') code = 'EG';
      if (code == 'SAU') code = 'SA';
      if (code.length != 2) return code;

      int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
      int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
      return String.fromCharCode(firstLetter) +
          String.fromCharCode(secondLetter);
    } catch (e) {
      return countryCode; // Gracefully return raw text on failure
    }
  }

  @override
  String toString() => 'SocketUser(id: $id, name: $name, nickname: $nickname)';
}

/// Payload for the 'auction_change_product' event.
/// 
/// Emitted by the server when an auction switches active focus to a new item
/// or updates bid parameters for the current product.
class AuctionProductChangeEvent {
  /// Display title of the product currently under the hammer.
  final String product;
  
  /// The absolute current top bid price for this product.
  final num bidPrice;
  
  /// The specific minimum amount required for the next valid bid.
  final num minBidPrice;
  
  /// The original reserve or starting price of the product.
  final num actualPrice;

  /// Default constructor for product change event payloads.
  const AuctionProductChangeEvent({
    required this.product,
    required this.bidPrice,
    required this.minBidPrice,
    required this.actualPrice,
  });

  /// Parses product change metadata from server broadcast.
  factory AuctionProductChangeEvent.fromJson(Map<String, dynamic> json) {
    return AuctionProductChangeEvent(
      product: json['product'] as String,
      bidPrice: json['bidPrice'] as num,
      minBidPrice: json['minBidPrice'] as num,
      actualPrice: json['actualPrice'] as num,
    );
  }

  /// Exports the product state to JSON.
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

/// Specialized model for routing server-side session errors to the UI.
/// 
/// Used for non-HTTP errors like namespace issues, invalid event sequences, 
/// or server-side logic failures.
class SocketErrorEvent {
  /// User-friendly error message provided by the server.
  final String message;
  
  /// Optional machine-readable code for conditional error handling.
  final String? code;
  
  /// Extra metadata or context related to why the error occurred.
  final Map<String, dynamic>? details;

  /// Default constructor for socket error events.
  const SocketErrorEvent({required this.message, this.code, this.details});

  /// Parses the server-side socket error payload.
  factory SocketErrorEvent.fromJson(Map<String, dynamic> json) {
    return SocketErrorEvent(
      message: json['message'] as String,
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Exports the error data to JSON.
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

/// Payload for the 'auctionEnded' event.
/// 
/// Contains metadata about the completion of an auction, including the winner
/// and the final finalized state of the auction object.
class AuctionEndedEvent {
  /// Full details of the winning user. Null if the auction expired without bids.
  final SocketUser? winningUser;
  
  /// Database identifier for the auction session.
  final int auctionId;
  
  /// Snapshot of the final [AuctionModel] resolution.
  final AuctionModel? auction;
  
  /// The finalized "Hammer Price" of the auction.
  final num? finalBidAmount;
  
  /// Sequence number used to maintain strict ordering of events on the client.
  final int? seq;

  /// Returns the winner's display title or a fallback for anonymous endings.
  String get winnerName => winningUser?.displayTitle ?? 'Unknown';
  
  /// Identifier of the winner, used for "You Won" UI states.
  int? get winnerId => winningUser?.id;

  /// Default constructor for auction completion events.
  const AuctionEndedEvent({
    this.winningUser,
    required this.auctionId,
    this.auction,
    this.finalBidAmount,
    this.seq,
  });

  /// Parses the termination event from server-side emitters.
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

  /// Exports the end state metadata to JSON.
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

/// Payload for the 'newBid' event.
/// 
/// Emitted whenever any user successfully places a competitive bid, causing
/// the global price and history indicators to update.
class BidPlacedEvent {
  /// The authoritative authoritative record of the incoming high bid.
  final AuctionBid newBid;
  
  /// The updated rolling history of bids for the current item.
  final List<AuctionBid> auctionBids;
  
  /// The new minimum price that subsequent bids must exceed.
  final num? currentPrice;
  
  /// The server-updated expiry date (e.g., if a bid extended the timer).
  final DateTime? expiryDate;
  
  /// Sequence number for packet reordering protection.
  final int? seq;

  /// Default constructor for successful bid placement events.
  const BidPlacedEvent({
    required this.newBid,
    required this.auctionBids,
    this.currentPrice,
    this.expiryDate,
    this.seq,
  });

  /// Parses bid placement metadata from the socket broadcast.
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

  /// Exports the bid event details to JSON.
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

/// Payload for the 'auctionItemEnded' event.
/// 
/// Signifies the completion of an individual unit within a multi-item auction,
/// triggering a UI transition to the [nextItem].
class AuctionItemEndedEvent {
  /// Authoritative parent auction model.
  final AuctionModel auction;
  
  /// Metadata for the next product in the sequence. Null if it was the last item.
  final AuctionProducts? nextItem;
  
  /// Identity of the winner for the specific unit that just closed.
  final SocketUser? winner;
  
  /// Sequence number for causality tracking.
  final int? seq;

  /// Default constructor for multi-item sequence transitions.
  const AuctionItemEndedEvent({
    required this.auction,
    this.nextItem,
    this.winner,
    this.seq,
  });

  /// Parses transition metadata from server emitters.
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

  /// Exports the item transition state to JSON.
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

/// Server feedback when a user's local bid attempt is rejected.
/// 
/// Contains localized explanation as well as authoritative prices to help the 
/// client correct out-of-sync local widgets without a total room re-sync.
class BidRejectedEvent {
  /// Reason for the rejection provided by server-side validation.
  final String message;
  
  /// The authoritative current top bid price.
  final num? currentPrice;
  
  /// The specific minimum price currently required to beat the high bid.
  final num? minimumBid;
  
  /// The product ID for which the bid attempt was made.
  final int? productId;

  /// Default constructor for bid rejection notifications.
  const BidRejectedEvent({
    required this.message,
    this.currentPrice,
    this.minimumBid,
    this.productId,
  });

  /// Parses rejection details from the socket broadcast.
  factory BidRejectedEvent.fromJson(Map<String, dynamic> json) {
    return BidRejectedEvent(
      message: (json['message'] as String?) ?? '',
      currentPrice: json['currentPrice'] as num?,
      minimumBid: json['minimumBid'] as num?,
      productId: json['productId'] as int?,
    );
  }

  /// Exports rejection info for local debugging and state correction.
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

/// Payload for the authoritative 'auctionStateUpdate' broadcast.
/// 
/// This is the "Pulse" event, emitted frequently to reset all connected 
/// clients to the server's absolute source of truth.
class AuctionStateUpdateEvent {
  /// identifier of the auction room being updated.
  final int auctionId;
  
  /// Authoritative server-calculated timer ending point.
  final DateTime? expiryDate;
  
  /// Identifier of the specific product that should be "Active" in the UI.
  final int? currentProductId;
  
  /// Cumulative snapshot of every product's individual state in this session.
  final List<StateUpdateProduct> products;
  
  /// State sequence ID for causality tracking in distributed networks.
  final int? seq;

  /// Default constructor for global state synchronization.
  const AuctionStateUpdateEvent({
    required this.auctionId,
    this.expiryDate,
    this.currentProductId,
    required this.products,
    this.seq,
  });

  /// Parses a global room state snapshot from server broadcast.
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

  /// Exports the system-wide snapshot to JSON.
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

/// A nested snapshot of an individual product's state within a room.
class StateUpdateProduct {
  /// identifier for the product unit.
  final int? id;
  
  /// Specialized localization: Name in Arabic.
  final String? productAr;
  
  /// Specialized localization: Name in English.
  final String? productEn;
  
  /// Authoritative current high bid price (often stringified for precision).
  final String? bidPrice;
  
  /// Authoritative minimum next bid (stringified for precision).
  final String? minBidPrice;
  
  /// Base starting price for baseline reference.
  final String? actualPrice;
  
  /// identifier of the parent room.
  final int? auctionId;
  
  /// Persistent high-confidence cached bids from the server database.
  final List<AuctionBid> topBids;

  /// Default constructor for nested product state snapshots.
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

  /// Parses a nested product state, resolving internal key naming discrepancies.
  factory StateUpdateProduct.fromJson(Map<String, dynamic> json) {
    return StateUpdateProduct(
      id: json['id'] as int?,
      // Resilience: Server key might be 'product' or 'product_ar'
      productAr: json['product_ar'] as String? ?? json['product'] as String?,
      productEn: json['product_en'] as String?,
      // Resilience: Numbers are often string-serialized in socket packets
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

  /// Exports the refined state snapshot to JSON for local state persistence.
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


