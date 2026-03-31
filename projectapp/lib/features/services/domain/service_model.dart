class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int durationMinutes;
  final int dailyLimit;
  final String? category;
  final String? imageUrl;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationMinutes,
    required this.dailyLimit,
    this.category,
    this.imageUrl,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    price: (json['price'] as num).toDouble(),
    durationMinutes: json['duration_minutes'],
    dailyLimit: json['daily_limit'],
    category: json['category'],
    imageUrl: json['image_url'],
    isActive: json['is_active'] ?? true,
  );
}
