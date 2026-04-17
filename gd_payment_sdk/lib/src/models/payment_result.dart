class GDPaymentResult {
  final String? orderId;
  final String? tokenId;
  final String? agreementId;
  final PaymentMethodResult? paymentMethod;

  GDPaymentResult({
    this.orderId,
    this.tokenId,
    this.agreementId,
    this.paymentMethod,
  });

  factory GDPaymentResult.fromJson(Map<String, dynamic> json) {
    return GDPaymentResult(
      orderId: json['orderId'] as String?,
      tokenId: json['tokenId'] as String?,
      agreementId: json['agreementId'] as String?,
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethodResult.fromJson(
              json['paymentMethod'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'tokenId': tokenId,
      'agreementId': agreementId,
      'paymentMethod': paymentMethod?.toJson(),
    };
  }

  @override
  String toString() {
    return 'GDPaymentResult(orderId: $orderId, tokenId: $tokenId, '
        'agreementId: $agreementId, paymentMethod: $paymentMethod)';
  }
}

class PaymentMethodResult {
  final String? type;
  final String? brand;
  final String? cardholderName;
  final String? maskedCardNumber;
  final String? wallet;
  final ExpiryDateResult? expiryDate;

  PaymentMethodResult({
    this.type,
    this.brand,
    this.cardholderName,
    this.maskedCardNumber,
    this.wallet,
    this.expiryDate,
  });

  factory PaymentMethodResult.fromJson(Map<String, dynamic> json) {
    return PaymentMethodResult(
      type: json['type'] as String?,
      brand: json['brand'] as String?,
      cardholderName: json['cardholderName'] as String?,
      maskedCardNumber: json['maskedCardNumber'] as String?,
      wallet: json['wallet'] as String?,
      expiryDate: json['expiryDate'] != null
          ? ExpiryDateResult.fromJson(
              json['expiryDate'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'brand': brand,
      'cardholderName': cardholderName,
      'maskedCardNumber': maskedCardNumber,
      'wallet': wallet,
      'expiryDate': expiryDate?.toJson(),
    };
  }

  @override
  String toString() {
    return 'PaymentMethodResult(type: $type, brand: $brand, '
        'cardholderName: $cardholderName, maskedCardNumber: $maskedCardNumber, '
        'wallet: $wallet, expiryDate: $expiryDate)';
  }
}

class ExpiryDateResult {
  final int? month;
  final int? year;

  ExpiryDateResult({this.month, this.year});

  factory ExpiryDateResult.fromJson(Map<String, dynamic> json) {
    return ExpiryDateResult(
      month: json['month'] as int?,
      year: json['year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'month': month, 'year': year};
  }

  @override
  String toString() {
    return 'ExpiryDateResult(month: $month, year: $year)';
  }
}

class GDPaymentError {
  final String code;
  final String message;
  final String? details;

  GDPaymentError({required this.code, required this.message, this.details});

  factory GDPaymentError.fromJson(Map<String, dynamic> json) {
    return GDPaymentError(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message, 'details': details};
  }

  @override
  String toString() {
    return 'GDPaymentError(code: $code, message: $message, details: $details)';
  }
}

enum PaymentStatus {
  success,
  failure,
  canceled;

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'failure':
        return PaymentStatus.failure;
      case 'canceled':
        return PaymentStatus.canceled;
      default:
        throw ArgumentError('Unknown payment status: $status');
    }
  }
}

class PaymentResponse {
  final PaymentStatus status;
  final GDPaymentResult? result;
  final GDPaymentError? error;

  PaymentResponse({required this.status, this.result, this.error});

  factory PaymentResponse.success(GDPaymentResult result) {
    return PaymentResponse(status: PaymentStatus.success, result: result);
  }

  factory PaymentResponse.failure(GDPaymentError error) {
    return PaymentResponse(status: PaymentStatus.failure, error: error);
  }

  factory PaymentResponse.canceled() {
    return PaymentResponse(status: PaymentStatus.canceled);
  }

  @override
  String toString() {
    return 'PaymentResponse(status: $status, result: $result, error: $error)';
  }
}
