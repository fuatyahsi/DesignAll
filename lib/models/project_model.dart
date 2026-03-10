class ProjectModel {
  final String id;
  final String name;
  final String? location;
  final String? imageUrl;
  final String? clientName;
  final String? roomType;
  final List<String>? tags;
  final double? budget;
  final String? status; // 'active', 'completed', 'paused'
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;

  ProjectModel({
    required this.id,
    required this.name,
    this.location,
    this.imageUrl,
    this.clientName,
    this.roomType,
    this.tags,
    this.budget,
    this.status = 'active',
    this.notes,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      location: json['location'],
      imageUrl: json['image_url'],
      clientName: json['client_name'],
      roomType: json['room_type'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      budget: json['budget']?.toDouble(),
      status: json['status'] ?? 'active',
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'image_url': imageUrl,
      'client_name': clientName,
      'room_type': roomType,
      'tags': tags,
      'budget': budget,
      'status': status,
      'notes': notes,
      'user_id': userId,
    };
  }

  ProjectModel copyWith({
    String? name,
    String? location,
    String? imageUrl,
    String? clientName,
    String? roomType,
    List<String>? tags,
    double? budget,
    String? status,
    String? notes,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      clientName: clientName ?? this.clientName,
      roomType: roomType ?? this.roomType,
      tags: tags ?? this.tags,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      userId: userId,
    );
  }
}
