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
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? '') ?? 0,
      productId: json['product_id'] != null ? int.tryParse(json['product_id'].toString()) : null,
      auctionProductId: json['auction_product_id'] != null ? int.tryParse(json['auction_product_id'].toString()) : null,
      winningId: json['winning_id'] != null ? int.tryParse(json['winning_id'].toString()) : null,
      quantity: json['quantity'] != null ? int.tryParse(json['quantity'].toString()) ?? 1 : 1,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
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
    if (winning != null && winning!['product'] != null) {
      return winning!['product']['product'] ?? '';
    }
    return '';
  }

  String localizedTitle(String locale) {
    if (locale == 'ar') {
      if (product != null) {
        return product!['title_ar'] ?? product!['name_ar'] ?? title;
      }
      if (auctionProduct != null) {
        return auctionProduct!['product_ar'] ?? title;
      }
      if (winning != null && winning!['product'] != null) {
        return winning!['product']['product_ar'] ?? title;
      }
    } else {
      if (product != null) {
        return product!['title_en'] ?? product!['name_en'] ?? title;
      }
      if (auctionProduct != null) {
        return auctionProduct!['product_en'] ?? title;
      }
      if (winning != null && winning!['product'] != null) {
        return winning!['product']['product_en'] ?? title;
      }
    }
    return title;
  }

  String localizedDescription(String locale) {
    if (locale == 'ar') {
      if (product != null) {
        return product!['description_ar'] ??
            product!['desc_ar'] ??
            product!['description'] ??
            '';
      }
      if (auctionProduct != null) {
        return auctionProduct!['description_ar'] ??
            auctionProduct!['description'] ??
            '';
      }
      if (winning != null && winning!['product'] != null) {
        return winning!['product']['description_ar'] ??
            winning!['product']['description'] ??
            '';
      }
    } else {
      if (product != null) {
        return product!['description_en'] ??
            product!['desc_en'] ??
            product!['description'] ??
            '';
      }
      if (auctionProduct != null) {
        return auctionProduct!['description_en'] ??
            auctionProduct!['description'] ??
            '';
      }
      if (winning != null && winning!['product'] != null) {
        return winning!['product']['description_en'] ??
            winning!['product']['description'] ??
            '';
      }
    }
    return '';
  }
}
