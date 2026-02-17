class UserModel {
  final int? id;
  final String? name;
  final String? password; // Raw password for signup/local cache
  final String? passwordHashed; // Hashed password from DB
  final String? phone_number;
  final bool? isAdmin;
  final bool? isSuperAdmin;
  final bool? isVerified;
  final String? createdAt;
  final String? updatedAt;

  //<editor-fold desc="Data Methods">
  const UserModel({
    this.id,
    this.name,
    this.password,
    this.passwordHashed,
    this.phone_number,
    this.isAdmin,
    this.isSuperAdmin,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          password == other.password &&
          passwordHashed == other.passwordHashed &&
          phone_number == other.phone_number &&
          isAdmin == other.isAdmin &&
          isSuperAdmin == other.isSuperAdmin &&
          isVerified == other.isVerified &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      password.hashCode ^
      passwordHashed.hashCode ^
      phone_number.hashCode ^
      isAdmin.hashCode ^
      isSuperAdmin.hashCode ^
      isVerified.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'UserModel{'
        ' id: $id,'
        ' name: $name,'
        ' password: $password,'
        ' passwordHashed: $passwordHashed,'
        ' phone_number: $phone_number,'
        ' isAdmin: $isAdmin,'
        ' isSuperAdmin: $isSuperAdmin,'
        ' isVerified: $isVerified,'
        ' createdAt: $createdAt,'
        ' updatedAt: $updatedAt,'
        '}';
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? password,
    String? passwordHashed,
    String? phone_number,
    bool? isAdmin,
    bool? isSuperAdmin,
    bool? isVerified,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      passwordHashed: passwordHashed ?? this.passwordHashed,
      phone_number: phone_number ?? this.phone_number,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'passwordHashed': passwordHashed,
      'phone_number': phone_number,
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String?,
      password: map['password'] as String?, // Might be null from DB
      passwordHashed: map['passwordHashed'] as String?,
      phone_number: map['phone_number'] as String?,
      isAdmin: map['isAdmin'] as bool?,
      isSuperAdmin: map['isSuperAdmin'] as bool?,
      isVerified: map['isVerified'] as bool?,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  //</editor-fold>
}
