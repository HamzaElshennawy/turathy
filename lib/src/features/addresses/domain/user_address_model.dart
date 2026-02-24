class UserAddressModel {
  final int id;
  final int userId;
  final String? label;
  final String name;
  final String mobile;
  final String country;
  final String city;
  final String address;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserAddressModel({
    required this.id,
    required this.userId,
    this.label,
    required this.name,
    required this.mobile,
    required this.country,
    required this.city,
    required this.address,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      label: json['label'] as String?,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      country: json['country'] as String,
      city: json['city'] as String,
      address: json['address'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (label != null) 'label': label,
      'name': name,
      'mobile': mobile,
      'country': country,
      'city': city,
      'address': address,
      'isDefault': isDefault,
    };
  }

  UserAddressModel copyWith({
    int? id,
    int? userId,
    String? label,
    String? name,
    String? mobile,
    String? country,
    String? city,
    String? address,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      country: country ?? this.country,
      city: city ?? this.city,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAddressModel &&
          runtimeType == other.runtimeType &&
          id == other.id);

  @override
  int get hashCode => id.hashCode;

  String get displayLabel => label ?? address;

  String get fullAddress => '$address, $city, $country';
}
