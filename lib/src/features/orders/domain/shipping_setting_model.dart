class ShippingSettingModel {
  final String key;
  final int fee;
  final String labelAr;
  final String labelEn;

  ShippingSettingModel({
    required this.key,
    required this.fee,
    required this.labelAr,
    required this.labelEn,
  });

  factory ShippingSettingModel.fromJson(Map<String, dynamic> json) {
    return ShippingSettingModel(
      key: json['key'] as String,
      fee: (json['fee'] as num).toInt(),
      labelAr: json['label_ar'] as String,
      labelEn: json['label_en'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'fee': fee,
      'label_ar': labelAr,
      'label_en': labelEn,
    };
  }
}
