class User {
  final int id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final int? departmentId;

  User({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.departmentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'Unknown User',
      email: json['email'],
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'Unknown',
      departmentId: json['department_id'],
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
    };
  }
}