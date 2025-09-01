// lib/models/workproof_model.dart
class Workproof {
  final int id;
  final int grievanceId;
  final int uploadedBy;
  final String filePath;
  final String? notes;
  final DateTime uploadedAt;

  Workproof({
    required this.id,
    required this.grievanceId,
    required this.uploadedBy,
    required this.filePath,
    this.notes,
    required this.uploadedAt,
  });

  factory Workproof.fromJson(Map<String, dynamic> json) {
    return Workproof(
      id: json['id'],
      grievanceId: json['grievance_id'],
      uploadedBy: json['uploaded_by'],
      filePath: json['file_path'],
      notes: json['notes'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}