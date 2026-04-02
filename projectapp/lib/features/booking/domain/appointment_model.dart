class AppointmentModel {
  final String id;
  final String customerId;
  final String? staffId;
  final String? staffName;
  final String? staffAvatar;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final String? notes;
  final List<String> serviceNames;
  final double totalPrice;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.customerId,
    this.staffId,
    this.staffName,
    this.staffAvatar,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.notes,
    required this.serviceNames,
    required this.totalPrice,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final services = (json['appointment_services'] as List? ?? []);
    return AppointmentModel(
      id: json['id'],
      customerId: json['customer_id'],
      staffId: json['staff_id'],
      staffName: json['staff']?['profiles']?['full_name'],
      staffAvatar: json['staff']?['profiles']?['avatar_url'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      appointmentTime: json['appointment_time'],
      status: json['status'],
      notes: json['notes'],
      serviceNames: services
          .map((s) => s['services']['name'] as String)
          .toList(),
      totalPrice: services.fold(
        0.0,
        (sum, s) => sum + (s['price_at_booking'] as num).toDouble(),
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
