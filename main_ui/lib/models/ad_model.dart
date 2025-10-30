// lib/models/ad_model.dart

import 'package:main_ui/utils/constants.dart';

class Advertisement {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;
  final bool isActive;
  final DateTime? createdAt;

  Advertisement({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
    required this.isActive,
    this.createdAt,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse boolean values which might come as strings
    bool _parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return false; // Default to false if format is unknown
    }

    return Advertisement(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] != null ? '${Constants.baseUrl}/uploads/${json['image_url']}' : null,
      linkUrl: json['link_url'] as String?,
      isActive: _parseBool(json['is_active'] ?? false),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };
}