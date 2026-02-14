class ServiceModel {
  final String id;
  final String name;
  final double price;
  final int duration;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      duration: json['duration'],
    );
  }
}
