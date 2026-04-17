class SavedPaymentMethodModel {
  final int id;
  final String provider;
  final String? brand;
  final String? last4;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cardholderName;
  final bool isDefault;
  final bool isActive;

  const SavedPaymentMethodModel({
    required this.id,
    required this.provider,
    this.brand,
    this.last4,
    this.expiryMonth,
    this.expiryYear,
    this.cardholderName,
    this.isDefault = false,
    this.isActive = true,
  });

  String get maskedLabel {
    final brandLabel = (brand == null || brand!.trim().isEmpty)
        ? 'Card'
        : brand!.trim();
    final suffix = (last4 == null || last4!.trim().isEmpty)
        ? ''
        : ' •••• $last4';
    return '$brandLabel$suffix';
  }

  String get expiryLabel {
    if ((expiryMonth ?? '').isEmpty || (expiryYear ?? '').isEmpty) {
      return '';
    }

    return '${expiryMonth!.padLeft(2, '0')}/$expiryYear';
  }

  factory SavedPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethodModel(
      id: json['id'] as int? ?? 0,
      provider: json['provider'] as String? ?? 'GEIDEA',
      brand: json['brand'] as String?,
      last4: json['last4'] as String?,
      expiryMonth: json['expiry_month'] as String?,
      expiryYear: json['expiry_year'] as String?,
      cardholderName: json['cardholder_name'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
