// lib/models/workproof_model.dart
import 'package:main_ui/models/user_model.dart';

class Workproof {
  final int id;
  final int grievanceId;
  final int uploadedBy;
  final String filePath;
  final String? notes;
  final DateTime uploadedAt;
  final User? uploader;

  Workproof({
    required this.id,
    required this.grievanceId,
    required this.uploadedBy,
    required this.filePath,
    this.notes,
    required this.uploadedAt,
    this.uploader,
  });

  factory Workproof.fromJson(Map<String, dynamic> json) {
    return Workproof(
      id: json['id'],
      grievanceId: json['grievance_id'],
      uploadedBy: json['uploaded_by'],
      filePath: json['file_path'],
      notes: json['notes'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      uploader: json['uploader'] != null ? User.fromJson(json['uploader']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notes': notes,
      // Add other fields if needed for sending data to the server
    };
  }
}