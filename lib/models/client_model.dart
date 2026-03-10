class ClientModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final String? avatarUrl;
  final DateTime createdAt;
  final String userId;

  ClientModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.notes,
    this.avatarUrl,
    required this.createdAt,
    required this.userId,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      notes: json['notes'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'avatar_url': avatarUrl,
      'user_id': userId,
    };
  }
}
