class User {
  final int id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final int? departmentId;
  final String? address;
  final String? profilePicture;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final bool twoFactorEnabled;
  final bool isActive;

  User({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.departmentId,
    this.address,
    this.profilePicture,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.twoFactorEnabled = false,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'Unknown User',
      email: json['email'],
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'Unknown',
      departmentId: json['department_id'],
      address: json['address'],
      profilePicture: json['profile_picture'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'department_id': departmentId,
      'address': address,
      'profile_picture': profilePicture,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'two_factor_enabled': twoFactorEnabled,
      'is_active': isActive,
    };
  }
}
