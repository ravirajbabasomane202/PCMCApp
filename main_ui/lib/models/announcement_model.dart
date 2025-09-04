// D:\Company_Data\PCMCApp\main_ui\lib\models\announcement_model.dart
class Announcement {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? targetRole;
  final bool isActive;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    this.targetRole,
    required this.isActive,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      targetRole: json['target_role'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'target_role': targetRole,
      'is_active': isActive,
    };
  }
}