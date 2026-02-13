class BookingModel {
  final String id;
  final String userId;
  final String serviceId;
  final DateTime bookingDate;
  final String timeSlot;
  final String status;

  BookingModel({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.bookingDate,
    required this.timeSlot,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userId: json['user_id'],
      serviceId: json['service_id'],
      bookingDate: DateTime.parse(json['booking_date']),
      timeSlot: json['time_slot'],
      status: json['status'],
    );
  }
}
