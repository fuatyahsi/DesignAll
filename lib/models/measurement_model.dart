class MeasurementModel {
  final String id;
  final String projectId;
  final String label; // 'Duvar A-B', 'Pencere genişliği' vb.
  final double distanceMeters;
  final DateTime createdAt;

  MeasurementModel({
    required this.id,
    required this.projectId,
    required this.label,
    required this.distanceMeters,
    required this.createdAt,
  });

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
      id: json['id'].toString(),
      projectId: json['project_id'].toString(),
      label: json['label'] ?? '',
      distanceMeters: (json['distance_meters'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'label': label,
      'distance_meters': distanceMeters,
    };
  }

  String get formattedDistance {
    if (distanceMeters >= 1) {
      return '${distanceMeters.toStringAsFixed(2)} m';
    } else {
      return '${(distanceMeters * 100).toStringAsFixed(1)} cm';
    }
  }
}
