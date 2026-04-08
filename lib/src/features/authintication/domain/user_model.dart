/// {@category Domain}
///
/// Representative model for a user in the Turathy system.
/// 
/// This class encapsulates all user attributes, including authentication state, 
/// authorization levels (isAdmin), and profile completeness status.
class UserModel {
  /// Unique identifier from the database.
  final int? id;

  /// Full display name of the user.
  final String? name;

  /// Raw password from input (typically used during signup or local caching).
  final String? password;

  /// Hashed password string returned from the backend.
  final String? passwordHashed;

  /// Primary contact number, including country code.
  final String? phone_number;

  /// Primary email address.
  final String? email;

  /// URL of the user's profile picture, if any.
  final String? profilePicUrl;

  /// Unique username or display alias.
  final String? nickname;

  /// Country of origin or residence.
  final String? nationality;

  /// Whether the user has administrative privileges.
  final bool? isAdmin;

  /// Whether the user has top-level system-wide privileges.
  final bool? isSuperAdmin;

  /// Whether the user's phone/email has been verified.
  final bool? isVerified;

  /// Whether the user has completed all required profile fields.
  final bool? isProfileComplete;

  /// A list of field names that are still required to complete the profile.
  /// 
  /// If this list is not empty, the UI should redirect the user to 
  /// the Complete Profile screen.
  final List<String>? missingFields;

  /// ISO 8601 timestamp of record creation.
  final String? createdAt;

  /// ISO 8601 timestamp of last record update.
  final String? updatedAt;

  const UserModel({
    this.id,
    this.name,
    this.password,
    this.passwordHashed,
    this.phone_number,
    this.email,
    this.profilePicUrl,
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
          profilePicUrl == other.profilePicUrl &&
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
      profilePicUrl.hashCode ^
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
        ' profilePicUrl: $profilePicUrl,'
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
    String? profilePicUrl,
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
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
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
      'profilePicUrl': profilePicUrl,
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
      password: map['password'] as String?,
      passwordHashed: map['passwordHashed'] as String?,
      // API sometimes returns 'number' instead of 'phone_number' in certain response structures.
      phone_number: (map['phone_number'] ?? map['number']) as String?,
      email: map['email'] as String?,
      profilePicUrl: map['profilePicUrl'] as String?,
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
}

