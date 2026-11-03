import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helper/dio/dio_helper.dart';
import '../../../core/helper/dio/end_points.dart';

class AppConfig {
  const AppConfig({
    required this.whatsappEnabled,
    required this.whatsappNumber,
    required this.whatsappDefaultMessage,
    required this.occasionId,
    required this.occasionColor,
    this.occasionLogoUrl,
    this.occasionBannerUrl,
  });

  final bool whatsappEnabled;
  final String whatsappNumber;
  final String whatsappDefaultMessage;
  final String occasionId;
  final String occasionColor;
  final String? occasionLogoUrl;
  final String? occasionBannerUrl;

  static const fallbackColor = '#005D24';
  static const knownOccasionIds = {
    'default',
    'national_day',
    'founding_day',
    'flag_day',
    'eid',
    'custom',
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final enabledRaw = json['whatsapp_enabled'];
    final enabled = enabledRaw is bool
        ? enabledRaw
        : enabledRaw?.toString().toLowerCase() == 'true';
    final occasion = _readOccasion(json['occasion']);
    return AppConfig(
      whatsappEnabled: enabled,
      whatsappNumber: json['whatsapp_number']?.toString() ?? '',
      whatsappDefaultMessage:
          json['whatsapp_default_message']?.toString() ?? '',
      occasionId: occasion.id,
      occasionColor: occasion.color,
      occasionLogoUrl: occasion.logoUrl,
      occasionBannerUrl: occasion.bannerUrl,
    );
  }
}

class _OccasionFields {
  const _OccasionFields({
    required this.id,
    required this.color,
    this.logoUrl,
    this.bannerUrl,
  });

  final String id;
  final String color;
  final String? logoUrl;
  final String? bannerUrl;
}

_OccasionFields _readOccasion(Object? raw) {
  const fallback = _OccasionFields(id: 'default', color: AppConfig.fallbackColor);
  if (raw is! Map) return fallback;
  final id = raw['id']?.toString().trim() ?? '';
  if (!AppConfig.knownOccasionIds.contains(id)) return fallback;
  final color = raw['color']?.toString().trim() ?? '';
  final parsed = RegExp(r'^#([0-9a-fA-F]{6})$').hasMatch(color)
      ? color
      : AppConfig.fallbackColor;
  return _OccasionFields(
    id: id,
    color: parsed,
    logoUrl: _mediaUrl(raw['logo_url']?.toString()),
    bannerUrl: _mediaUrl(raw['banner_url']?.toString()),
  );
}

String? _mediaUrl(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final base = EndPoints.baseUrl.endsWith('/')
      ? EndPoints.baseUrl.substring(0, EndPoints.baseUrl.length - 1)
      : EndPoints.baseUrl;
  if (value.startsWith('/')) return '$base$value';
  return '$base/$value';
}

class AppConfigRepository {
  AppConfig? _cached;
  DateTime? _cachedAt;
  static const Duration _ttl = Duration(minutes: 3);

  Future<AppConfig> getConfig({bool force = false}) async {
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (!force &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _ttl) {
      return cached;
    }

    final result = await DioHelper.getData(url: EndPoints.getConfig);
    if (result.statusCode != 200) {
      throw Exception('Failed to load app config');
    }
    final data = result.data;
    final payload = data is Map && data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final config = AppConfig.fromJson(payload);
    _cached = config;
    _cachedAt = DateTime.now();
    return config;
  }
}

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository();
});

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return ref.watch(appConfigRepositoryProvider).getConfig();
});
