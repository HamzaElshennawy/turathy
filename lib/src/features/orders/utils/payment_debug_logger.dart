import 'dart:convert';
import 'dart:developer' as developer;

class PaymentDebugLogger {
  PaymentDebugLogger._();

  static const bool enabled = bool.fromEnvironment(
    'PAYMENT_DEBUG_LOGS',
    defaultValue: false,
  );

  static const _redactedKeys = <String>{
    'token',
    'authorization',
    'password',
    'signature',
    'secret',
    'apiKey',
    'api_key',
    'publicKey',
    'public_key',
    'cardnumber',
    'card_number',
    'pan',
    'cvv',
    'cvc',
    'expiry',
    'exp_month',
    'exp_year',
  };

  static void info(String event, {Map<String, Object?>? data}) {
    if (!enabled) return;
    developer.log(
      _format(event, data),
      name: 'PaymentFlow',
    );
  }

  static void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    if (!enabled) return;
    developer.log(
      _format(event, data),
      name: 'PaymentFlow',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  static String _format(String event, Map<String, Object?>? data) {
    if (data == null || data.isEmpty) return event;

    try {
      return '$event ${jsonEncode(_sanitizeMap(data))}';
    } catch (_) {
      return '$event ${data.toString()}';
    }
  }

  static Map<String, Object?> _sanitizeMap(Map<String, Object?> data) {
    return data.map((key, value) {
      final normalized = key.toLowerCase();
      if (_redactedKeys.contains(normalized)) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, _sanitizeValue(value));
    });
  }

  static Object? _sanitizeValue(Object? value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _redactedKeys.contains(key.toString().toLowerCase())
              ? '***'
              : _sanitizeValue(nestedValue),
        ),
      );
    }
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList();
    }
    if (value is String && value.length > 500) {
      return '${value.substring(0, 500)}...';
    }
    return value;
  }
}
