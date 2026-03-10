class BudgetItemModel {
  final String id;
  final String projectId;
  final String category; // 'Mobilya', 'Boya', 'İşçilik', 'Aksesuar' vb.
  final String description;
  final double unitPrice;
  final int quantity;
  final bool isPurchased;
  final DateTime createdAt;

  BudgetItemModel({
    required this.id,
    required this.projectId,
    required this.category,
    required this.description,
    required this.unitPrice,
    this.quantity = 1,
    this.isPurchased = false,
    required this.createdAt,
  });

  double get totalPrice => unitPrice * quantity;

  factory BudgetItemModel.fromJson(Map<String, dynamic> json) {
    return BudgetItemModel(
      id: json['id'].toString(),
      projectId: json['project_id'].toString(),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      isPurchased: json['is_purchased'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'category': category,
      'description': description,
      'unit_price': unitPrice,
      'quantity': quantity,
      'is_purchased': isPurchased,
    };
  }
}
