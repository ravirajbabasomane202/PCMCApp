class MasterSubject {
  final int id;
  final String name;
  final String? description;

  MasterSubject({
    required this.id,
    required this.name,
    this.description,
  });

  factory MasterSubject.fromJson(Map<String, dynamic> json) {
    return MasterSubject(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class MasterArea {
  final int id;
  final String name;
  final String? description;

  MasterArea({
    required this.id,
    required this.name,
    this.description,
  });

  factory MasterArea.fromJson(Map<String, dynamic> json) {
    return MasterArea(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}