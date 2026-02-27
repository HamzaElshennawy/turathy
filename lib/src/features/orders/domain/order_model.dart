import 'package:intl/intl.dart';

import '../../auctions/domain/winning_auction_model.dart';

class OrderModel {
  final int id;
  final int userId;
  final int auctionId;
  final double total;
  final DateTime date;
  final int? addressId;
  final Map<String, dynamic>? address;
  final int pCs;
  final String codAmt;
  final String weight;
  final String itemDesc;
  final String? shipType;
  final String? sName;
  final String? sContact;
  final String? sAddr1;
  final String? sCity;
  final String? sPhone;
  final String? sCntry;
  final String? awbNo;
  final String? refNo;
  final String? paymentStatus;
  final String? orderStatus;
  final String? paymentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final Map<String, dynamic>? product;
  final Map<String, dynamic>? auction;
  final int? productId;
  final int? winningId;
  final int? auctionProductId;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.auctionId,
    required this.total,
    required this.date,
    this.addressId,
    this.address,
    required this.pCs,
    required this.codAmt,
    required this.weight,
    required this.itemDesc,
    this.shipType,
    this.sName,
    this.sContact,
    this.sAddr1,
    this.sCity,
    this.sPhone,
    this.sCntry,
    this.awbNo,
    this.refNo,
    this.paymentStatus,
    this.paymentId,
    this.orderStatus,
    this.createdAt,
    this.updatedAt,
    this.product,
    this.auction,
    this.productId,
    this.winningId,
    this.auctionProductId,
  });

  // Address helper getters — read from nested address object when available
  String get cName => address?['name'] as String? ?? '';
  String get cCountry => address?['country'] as String? ?? '';
  String get cCity => address?['city'] as String? ?? '';
  String get cMobile => address?['mobile'] as String? ?? '';
  String get cAddress => address?['address'] as String? ?? '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;

  OrderModel copyWith({
    int? id,
    int? userId,
    int? auctionId,
    double? total,
    DateTime? date,
    int? addressId,
    Map<String, dynamic>? address,
    int? pCs,
    String? codAmt,
    String? weight,
    String? itemDesc,
    String? shipType,
    String? sName,
    String? sContact,
    String? sAddr1,
    String? sCity,
    String? sPhone,
    String? sCntry,
    String? awbNo,
    String? refNo,
    String? paymentStatus,
    String? paymentId,
    String? orderStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? product,
    Map<String, dynamic>? auction,
    int? productId,
    int? winningId,
    int? auctionProductId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      auctionId: auctionId ?? this.auctionId,
      total: total ?? this.total,
      date: date ?? this.date,
      addressId: addressId ?? this.addressId,
      address: address ?? this.address,
      pCs: pCs ?? this.pCs,
      codAmt: codAmt ?? this.codAmt,
      weight: weight ?? this.weight,
      itemDesc: itemDesc ?? this.itemDesc,
      shipType: shipType ?? this.shipType,
      sName: sName ?? this.sName,
      sContact: sContact ?? this.sContact,
      sAddr1: sAddr1 ?? this.sAddr1,
      sCity: sCity ?? this.sCity,
      sPhone: sPhone ?? this.sPhone,
      sCntry: sCntry ?? this.sCntry,
      awbNo: awbNo ?? this.awbNo,
      refNo: refNo ?? this.refNo,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      orderStatus: orderStatus ?? this.orderStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
      auction: auction ?? this.auction,
      productId: productId ?? this.productId,
      winningId: winningId ?? this.winningId,
      auctionProductId: auctionProductId ?? this.auctionProductId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'auction_id': auctionId,
      'product_id': productId,
      'auction_product_id': auctionProductId,
      'winning_id': winningId,
      'total': total,
      'date': DateFormat('yyyy-MM-dd', 'en_US').format(date),
      'address_id': addressId,
      'PCs': pCs,
      'codAmt': num.tryParse(codAmt) ?? 0,
      'weight': weight,
      'itemDesc': itemDesc,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (paymentId != null) 'payment_id': paymentId,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      userId: (json['user_id'] ?? 0) as int,
      auctionId: (json['auction_id'] ?? 0) as int,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      addressId: json['address_id'] as int?,
      address:
          (json['address'] ?? json['user_addresses']) as Map<String, dynamic>?,
      pCs: (json['PCs'] ?? 1) as int,
      codAmt: (json['codAmt'] ?? 0).toString(),
      weight: (json['weight'] ?? '1').toString(),
      itemDesc: json['itemDesc'] as String? ?? '',
      shipType: json['shipType'] as String?,
      sName: json['sName'] as String?,
      sContact: json['sContact'] as String?,
      sAddr1: json['sAddr1'] as String?,
      sCity: json['sCity'] as String?,
      sPhone: json['sPhone'] as String?,
      sCntry: json['sCntry'] as String?,
      awbNo: json['AWBNo'] as String?,
      refNo: json['refNo'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      paymentId: json['payment_id'] as String?,
      orderStatus: json['orderStatus'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      product: json['product'],
      auction: json['auction'],
      productId: json['product_id'] as int?,
      auctionProductId: json['auction_product_id'] as int?,
      winningId: json['winning_id'] as int?,
    );
  }

  factory OrderModel.fromWinningAuction(WinningAuctionModel winningAuction) {
    return OrderModel(
      id: 0,
      userId: winningAuction.userId,
      auctionId: winningAuction.auctionId,
      productId: null,
      auctionProductId: winningAuction.productId,
      winningId: winningAuction.id != 0 ? winningAuction.id : null,
      total: winningAuction.price,
      date: DateTime.now(),
      pCs: 1,
      codAmt: '0',
      weight: '1',
      itemDesc: winningAuction.product,
    );
  }
}
