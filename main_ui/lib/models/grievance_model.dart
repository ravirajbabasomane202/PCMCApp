import 'package:main_ui/models/comment_model.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/models/master_data_model.dart';
import 'package:main_ui/models/workproof_model.dart';
class Assignee {
  final String? name;

  Assignee({this.name});

  factory Assignee.fromJson(Map<String, dynamic> json) {
    return Assignee(
      name: json['name'] as String?,
    );
  }
}

class Grievance {
  final int id;
  final String complaintId;
  final int? citizenId;
  final int? subjectId;
  final int? areaId;
  final String title;
  final String description;
  final String? wardNumber;
  final String? status;
  final String? priority;
  final int? assignedTo;
  final int? assignedBy;
  final String? rejectionReason;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int escalationLevel;
  final int? feedbackRating;
  final String? feedbackText;
  final User? citizen;
  final User? assignee;
  final MasterSubject? subject;
  final MasterArea? area;
  final List<GrievanceAttachment>? attachments; // From old version
  final List<Comment>? comments; // From old version
  final List<Workproof>? workproofs;

  Grievance({
    required this.id,
    required this.complaintId,
    this.citizenId,
    this.subjectId,
    this.areaId,
    required this.title,
    required this.description,
    this.wardNumber,
    this.status,
    this.priority,
    this.assignedTo,
    this.assignedBy,
    this.rejectionReason,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.address,
    required this.escalationLevel,
    this.feedbackRating,
    this.feedbackText,
    this.citizen,
    this.assignee,
    this.subject,
    this.area,
    this.attachments,
    this.comments,
    this.workproofs,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
  
  return Grievance(
    id: json['id'] as int,
    complaintId: json['complaint_id'] as String,
    citizenId: json['citizen'] != null ? json['citizen']['id'] as int? : null,
    subjectId: json['subject'] != null ? json['subject']['id'] as int? : null,
    areaId: json['area'] != null ? json['area']['id'] as int? : null,
    title: json['title'] as String? ?? 'Untitled', // Provide default if null
    description: json['description'] as String? ?? '', // Provide default if null
    wardNumber: json['ward_number'] as String?,
    status: json['status'] as String?,
    priority: json['priority'] as String?,
    assignedTo: json['assignee'] != null ? json['assignee']['id'] as int? : null,
    assignedBy: json['assigner'] != null ? json['assigner']['id'] as int? : null,
    rejectionReason: json['rejection_reason'] as String?,
    resolvedAt: json['resolved_at'] != null
        ? DateTime.parse(json['resolved_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    latitude: json['latitude'] is double ? json['latitude'] : null,
    longitude: json['longitude'] is double ? json['longitude'] : null,
    address: json['address'] as String?,
    escalationLevel: json['escalation_level'] as int? ?? 0,
    feedbackRating: json['feedback_rating'] as int?,
    feedbackText: json['feedback_text'] as String?,
    citizen: json['citizen'] != null
        ? User.fromJson(json['citizen'] as Map<String, dynamic>)
        : null,
    assignee: json['assignee'] != null
        ? User.fromJson(json['assignee'] as Map<String, dynamic>)
        : null,
    subject: json['subject'] != null
        ? MasterSubject.fromJson(json['subject'] as Map<String, dynamic>)
        : null,
    area: json['area'] != null
        ? MasterArea.fromJson(json['area'] as Map<String, dynamic>)
        : null,
    attachments: json['attachments'] != null
        ? (json['attachments'] as List).map((a) => GrievanceAttachment.fromJson(a)).toList()
        : null,
    comments: json['comments'] != null
        ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
        : null,
      workproofs: json['workproofs'] != null
        ? (json['workproofs'] as List).map((wp) => Workproof.fromJson(wp)).toList()
        : null,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_id': complaintId,
      'citizen_id': citizenId,
      'subject_id': subjectId,
      'area_id': areaId,
      'title': title,
      'description': description,
      'ward_number': wardNumber,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'rejection_reason': rejectionReason,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'escalation_level': escalationLevel,
      'feedback_rating': feedbackRating,
      'feedback_text': feedbackText,
      'citizen': citizen?.toJson(),
      'assignee': assignee?.toJson(),
      'subject': subject?.toJson(),
      'area': area?.toJson(),
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'comments': comments?.map((c) => c.toJson()).toList(),
      'workproofs': workproofs?.map((wp) => wp.toJson()).toList(),
    };
  }
}

class GrievanceAttachment {
  final int id;
  final int grievanceId;
  final String filePath;
  final String fileType;
  final DateTime uploadedAt;

  GrievanceAttachment({
    required this.id,
    required this.grievanceId,
    required this.filePath,
    required this.fileType,
    required this.uploadedAt,
  });

  factory GrievanceAttachment.fromJson(Map<String, dynamic> json) {
    return GrievanceAttachment(
      id: json['id'] ?? 0,
      grievanceId: json['grievance_id'] ?? 0,
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grievance_id': grievanceId,
      'file_path': filePath,
      'file_type': fileType,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
