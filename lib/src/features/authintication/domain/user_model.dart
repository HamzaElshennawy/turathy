class UserModel {
  final int? id;
  final String? name;
  final String? password; // Raw password for signup/local cache
  final String? passwordHashed; // Hashed password from DB
  final String? phone_number;
  final String? email;
  final String? nickname;
  final String? nationality;
  final bool? isAdmin;
  final bool? isSuperAdmin;
  final bool? isVerified;
  final bool? isProfileComplete;
  final List<String>? missingFields;
  final String? createdAt;
  final String? updatedAt;

  ///<editor-fold desc="Data Methods">
  const UserModel({
    this.id,
    this.name,
    this.password,
    this.passwordHashed,
    this.phone_number,
    this.email,
    this.nickname,
    this.nationality,
    this.isAdmin,
    this.isSuperAdmin,
    this.isVerified,
    this.isProfileComplete,
    this.missingFields,
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
          email == other.email &&
          nickname == other.nickname &&
          nationality == other.nationality &&
          isAdmin == other.isAdmin &&
          isSuperAdmin == other.isSuperAdmin &&
          isVerified == other.isVerified &&
          isProfileComplete == other.isProfileComplete &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      password.hashCode ^
      passwordHashed.hashCode ^
      phone_number.hashCode ^
      email.hashCode ^
      nickname.hashCode ^
      nationality.hashCode ^
      isAdmin.hashCode ^
      isSuperAdmin.hashCode ^
      isVerified.hashCode ^
      isProfileComplete.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'UserModel{'
        ' id: $id,'
        ' name: $name,'
        ' phone_number: $phone_number,'
        ' email: $email,'
        ' nickname: $nickname,'
        ' nationality: $nationality,'
        ' isAdmin: $isAdmin,'
        ' isSuperAdmin: $isSuperAdmin,'
        ' isVerified: $isVerified,'
        ' isProfileComplete: $isProfileComplete,'
        ' missingFields: $missingFields,'
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
    String? email,
    String? nickname,
    String? nationality,
    bool? isAdmin,
    bool? isSuperAdmin,
    bool? isVerified,
    bool? isProfileComplete,
    List<String>? missingFields,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      passwordHashed: passwordHashed ?? this.passwordHashed,
      phone_number: phone_number ?? this.phone_number,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      nationality: nationality ?? this.nationality,
      isAdmin: isAdmin ?? this.isAdmin,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      isVerified: isVerified ?? this.isVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      missingFields: missingFields ?? this.missingFields,
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
      'email': email,
      'nickname': nickname,
      'nationality': nationality,
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'isVerified': isVerified,
      'isProfileComplete': isProfileComplete,
      'missingFields': missingFields,
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
      phone_number: (map['phone_number'] ?? map['number']) as String?,
      email: map['email'] as String?,
      nickname: map['nickname'] as String?,
      nationality: map['nationality'] as String?,
      isAdmin: map['isAdmin'] as bool?,
      isSuperAdmin: map['isSuperAdmin'] as bool?,
      isVerified: map['isVerified'] as bool?,
      isProfileComplete: map['isProfileComplete'] as bool?,
      missingFields: map['missingFields'] != null
          ? List<String>.from(map['missingFields'])
          : null,
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  ///<editor-fold>
}
