import '../../../features/products/domain/product_model.dart';

class CartItemModel {
  final int id;
  final int userId;
  final int productId;
  final int quantity;
  final ProductModel? product;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int? ?? 1,
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CartItemModel copyWith({
    int? id,
    int? userId,
    int? productId,
    int? quantity,
    ProductModel? product,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
