// lib/models/comment_model.dart
class Comment {
  final int id;
  final int grievanceId;
  final int userId;
  final String? commentText;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.grievanceId,
    required this.userId,
    this.commentText,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      grievanceId: json['grievance_id'] ,
      userId: json['user_id'],
      commentText: json['comment_text'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grievance_id': grievanceId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}