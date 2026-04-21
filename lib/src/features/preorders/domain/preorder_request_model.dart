import '../../products/domain/product_model.dart';

class PreorderRequestItemModel {
  final int id;
  final int preorderRequestId;
  final int productId;
  final int quantity;
  final ProductModel? product;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PreorderRequestItemModel({
    required this.id,
    required this.preorderRequestId,
    required this.productId,
    required this.quantity,
    this.product,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PreorderRequestItemModel.fromJson(Map<String, dynamic> json) {
    return PreorderRequestItemModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      preorderRequestId:
          int.tryParse(json['preorder_request_id']?.toString() ?? '') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      product: json['product'] is Map<String, dynamic>
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PreorderRequestModel {
  final int id;
  final String status;
  final String? notes;
  final List<PreorderRequestItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PreorderRequestModel({
    required this.id,
    required this.status,
    this.notes,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get isDraft => status == 'draft';

  factory PreorderRequestModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return PreorderRequestModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'draft',
      notes: json['notes'] as String?,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(PreorderRequestItemModel.fromJson)
              .toList()
          : const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
