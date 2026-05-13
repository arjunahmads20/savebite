class GoodCategory {
  final int id;
  final String name;
  final String color;

  GoodCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  factory GoodCategory.fromJson(Map<String, dynamic> json) {
    return GoodCategory(
      id: json['id'],
      name: json['name'] ?? 'Unknown Category',
      color: json['color'] ?? '#4CAF50',
    );
  }
}
