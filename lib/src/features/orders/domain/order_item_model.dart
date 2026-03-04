import '../../../core/helper/dio/end_points.dart';

class OrderItemModel {
  final int id;
  final int orderId;
  final int? productId;
  final int? auctionProductId;
  final int? winningId;
  final int quantity;
  final double price;
  final Map<String, dynamic>? product;
  final Map<String, dynamic>? auctionProduct;
  final Map<String, dynamic>? winning;

  OrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    this.auctionProductId,
    this.winningId,
    required this.quantity,
    required this.price,
    this.product,
    this.auctionProduct,
    this.winning,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      productId: json['product_id'] as int?,
      auctionProductId: json['auction_product_id'] as int?,
      winningId: json['winning_id'] as int?,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      product: json['product'] as Map<String, dynamic>?,
      auctionProduct: json['auction_product'] as Map<String, dynamic>?,
      winning: json['winning'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'auction_product_id': auctionProductId,
      'winning_id': winningId,
      'quantity': quantity,
      'price': price,
    };
  }

  String? get imageUrl {
    if (product != null) {
      if (product!['images'] != null &&
          (product!['images'] as List).isNotEmpty) {
        return product!['images'][0].toString();
      }
      return product!['image_url']?.toString() ??
          product!['main_image']?.toString();
    }
    if (auctionProduct != null) {
      return auctionProduct!['image']?.toString() ??
          auctionProduct!['image_url']?.toString();
    }
    return null;
  }

  String get fullImageUrl {
    final url = imageUrl;
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${EndPoints.baseUrl}$url';
  }

  String get title {
    if (product != null) return product!['title'] ?? product!['name'] ?? '';
    if (auctionProduct != null) return auctionProduct!['product'] ?? '';
    if (winning != null && winning!['product'] != null)
      return winning!['product']['product'] ?? '';
    return '';
  }
}
