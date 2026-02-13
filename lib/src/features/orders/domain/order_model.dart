import 'package:intl/intl.dart';

import '../../auctions/domain/winning_auction_model.dart';

class OrderModel {
  final int id;
  final int userId;
  final int auctionId;
  final double total;
  final DateTime date;
  final String cName;
  final String cCountry;
  final String cCity;
  final String cMobile;
  final String cAddress;
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

  const OrderModel({
    required this.id,
    required this.userId,
    required this.auctionId,
    required this.total,
    required this.date,
    required this.cName,
    required this.cCountry,
    required this.cCity,
    required this.cMobile,
    required this.cAddress,
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
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          auctionId == other.auctionId &&
          total == other.total &&
          date == other.date &&
          cName == other.cName &&
          cCountry == other.cCountry &&
          cCity == other.cCity &&
          cMobile == other.cMobile &&
          cAddress == other.cAddress &&
          pCs == other.pCs &&
          codAmt == other.codAmt &&
          weight == other.weight &&
          itemDesc == other.itemDesc &&
          shipType == other.shipType &&
          sName == other.sName &&
          sContact == other.sContact &&
          sAddr1 == other.sAddr1 &&
          sCity == other.sCity &&
          sPhone == other.sPhone &&
          sCntry == other.sCntry &&
          awbNo == other.awbNo &&
          refNo == other.refNo &&
          paymentStatus == other.paymentStatus &&
          paymentId == other.paymentId &&
          orderStatus == other.orderStatus &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          product == other.product &&
          auction == other.auction);

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      auctionId.hashCode ^
      total.hashCode ^
      date.hashCode ^
      cName.hashCode ^
      cCountry.hashCode ^
      cCity.hashCode ^
      cMobile.hashCode ^
      cAddress.hashCode ^
      pCs.hashCode ^
      codAmt.hashCode ^
      weight.hashCode ^
      itemDesc.hashCode ^
      shipType.hashCode ^
      sName.hashCode ^
      sContact.hashCode ^
      sAddr1.hashCode ^
      sCity.hashCode ^
      sPhone.hashCode ^
      sCntry.hashCode ^
      awbNo.hashCode ^
      refNo.hashCode ^
      paymentStatus.hashCode ^
      paymentId.hashCode ^
      orderStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      product.hashCode ^
      auction.hashCode;

  OrderModel copyWith({
    int? id,
    int? userId,
    int? auctionId,
    double? total,
    DateTime? date,
    String? cName,
    String? cCountry,
    String? cCity,
    String? cMobile,
    String? cAddress,
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
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      auctionId: auctionId ?? this.auctionId,
      total: total ?? this.total,
      date: date ?? this.date,
      cName: cName ?? this.cName,
      cCountry: cCountry ?? this.cCountry,
      cCity: cCity ?? this.cCity,
      cMobile: cMobile ?? this.cMobile,
      cAddress: cAddress ?? this.cAddress,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'auction_id': auctionId,
      'product_id': productId,
      'total': total,
      'date': DateFormat('yyyy-MM-dd', 'en_US').format(date),
      'cName': cName,
      'cCountry': cCountry,
      'cCity': cCity,
      'cMobile': cMobile,
      'cAddress': cAddress,
      'PCs': pCs,
      'codAmt': num.tryParse(codAmt) ?? 0,
      'weight': weight,
      'itemDesc': itemDesc,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      userId: (json['user_id'] ?? 0) as int,
      auctionId: (json['auction_id'] ?? 0) as int,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      cName: json['cName'] as String? ?? '',
      cCountry: json['cCountry'] as String? ?? '',
      cCity: json['cCity'] as String? ?? '',
      cMobile: json['cMobile'] as String? ?? '',
      cAddress: json['cAddress'] as String? ?? '',
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
    );
  }

  factory OrderModel.fromWinningAuction(WinningAuctionModel winningAuction) {
    return OrderModel(
      id: winningAuction.id,
      userId: winningAuction.userId,
      auctionId: winningAuction.auctionId,
      productId: null,
      total: winningAuction.price,
      date: DateTime.now(),
      cName: winningAuction.winnerName,
      cCountry: 'KSA', // Default value as per API example
      cCity: 'ULA', // Default value as per API example
      cMobile: '', // To be filled by user
      cAddress: '', // To be filled by user
      pCs: 1,
      codAmt: '0',
      weight: '1',
      itemDesc: winningAuction.product,
    );
  }
}
