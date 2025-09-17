// lib/models/comment_model.dart
class CommentAttachment {
  final int id;
  final String filePath;
  final String fileType;

  CommentAttachment({
    required this.id,
    required this.filePath,
    required this.fileType,
  });

  factory CommentAttachment.fromJson(Map<String, dynamic> json) {
    return CommentAttachment(
      id: json['id'] as int,
      filePath: json['file_path'] as String,
      fileType: json['file_type'] as String,
    );
  }
}
class Comment {
  final int id;
  final int grievanceId;
  final int userId;
  final String? userName;
  final String? commentText;
  final DateTime createdAt;
  final List<CommentAttachment>? attachments;

  Comment({
    required this.id,
    required this.grievanceId,
    required this.userId,
    this.userName,
    this.commentText,
    required this.createdAt,
    this.attachments,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      grievanceId: json['grievance_id'] ,
      userId: json['user_id'],
      userName: json['user']?['name'] as String?,
      commentText: json['comment_text'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((item) => CommentAttachment.fromJson(item)).toList()
          : null,
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