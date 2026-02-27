class AddressModel {
  final int? id;
  final int? userId;
  final String? label;
  final String? name;
  final String? mobile;
  final String? country;
  final String? city;
  final String? address;
  final bool? isDefault;
  final String? createdAt;
  final String? updatedAt;

  const AddressModel({
    this.id,
    this.userId,
    this.label,
    this.name,
    this.mobile,
    this.country,
    this.city,
    this.address,
    this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      label: json['label'] as String?,
      name: json['name'] as String?,
      mobile: json['mobile'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      isDefault: json['isDefault'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (label != null) 'label': label,
      if (name != null) 'name': name,
      if (mobile != null) 'mobile': mobile,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (address != null) 'address': address,
      if (isDefault != null) 'isDefault': isDefault,
    };
  }

  AddressModel copyWith({
    int? id,
    int? userId,
    String? label,
    String? name,
    String? mobile,
    String? country,
    String? city,
    String? address,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
  }) {
    return AddressModel(
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
  String toString() {
    return 'AddressModel{id: $id, label: $label, name: $name, city: $city, country: $country}';
  }
}
