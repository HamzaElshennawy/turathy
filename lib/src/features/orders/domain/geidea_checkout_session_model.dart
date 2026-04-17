class GeideaCheckoutSessionModel {
  const GeideaCheckoutSessionModel({
    required this.orderId,
    required this.merchantReferenceId,
    required this.provider,
    this.sessionId,
    this.checkoutUrl,
    this.rawResponse = const <String, dynamic>{},
  });

  final int orderId;
  final String merchantReferenceId;
  final String provider;
  final String? sessionId;
  final String? checkoutUrl;
  final Map<String, dynamic> rawResponse;

  factory GeideaCheckoutSessionModel.fromJson(Map<String, dynamic> json) {
    final rawResponse = json['response'] is Map
        ? Map<String, dynamic>.from(json['response'] as Map)
        : const <String, dynamic>{};
    final nestedSession = rawResponse['session'] is Map
        ? Map<String, dynamic>.from(rawResponse['session'] as Map)
        : const <String, dynamic>{};

    return GeideaCheckoutSessionModel(
      orderId: json['orderId'] as int? ?? 0,
      merchantReferenceId: json['merchantReferenceId'] as String? ?? '',
      provider: json['provider'] as String? ?? 'GEIDEA',
      sessionId:
          _readString(json, const ['sessionId']) ??
          _readString(rawResponse, const ['sessionId']) ??
          _readString(nestedSession, const ['id', 'sessionId']),
      checkoutUrl:
          _readString(json, const [
            'checkoutUrl',
            'paymentUrl',
            'redirectUrl',
            'redirect_url',
            'url',
          ]) ??
          _readString(rawResponse, const [
            'checkoutUrl',
            'paymentUrl',
            'redirectUrl',
            'redirect_url',
            'url',
          ]),
      rawResponse: rawResponse,
    );
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
