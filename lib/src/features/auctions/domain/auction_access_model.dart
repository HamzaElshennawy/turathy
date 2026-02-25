import 'package:turathy/src/features/auctions/domain/auction_model.dart';

class RequestAuctionAccessDto {
  final int userId;
  final int auctionId;

  RequestAuctionAccessDto({required this.userId, required this.auctionId});

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'auction_id': auctionId};
  }
}

class CheckAccessResponseModel {
  final String status; // 'GRANTED', 'DENIED', 'REQUIRED', 'PENDING'
  final String message;

  CheckAccessResponseModel({required this.status, required this.message});

  factory CheckAccessResponseModel.fromJson(Map<String, dynamic> json) {
    String status = 'REQUIRED';

    if (json['hasAccess'] == true) {
      status = 'GRANTED';
    } else if (json['request'] != null && json['request']['status'] != null) {
      status = json['request']['status'];
    }

    return CheckAccessResponseModel(
      status: status,
      message: json['reason'] ?? json['message'] ?? '',
    );
  }
}

class AuctionAccessModel {
  final int id;
  final int userId;
  final int auctionId;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final User? user;
  final AuctionModel? auction;

  AuctionAccessModel({
    required this.id,
    required this.userId,
    required this.auctionId,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.auction,
  });

  factory AuctionAccessModel.fromJson(Map<String, dynamic> json) {
    return AuctionAccessModel(
      id: json['id'],
      userId: json['user_id'],
      auctionId: json['auction_id'],
      status: json['status'] ?? 'PENDING',
      adminNotes: json['admin_notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      auction: json['auction'] != null
          ? AuctionModel.fromJson(json['auction'])
          : null,
    );
  }
}
