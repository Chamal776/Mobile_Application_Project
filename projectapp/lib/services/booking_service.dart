import 'package:supabase_flutter/supabase_flutter.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createBooking({
    required String serviceId,
    required DateTime bookingDate,
    required String timeSlot,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await _supabase.from('bookings').insert({
      'user_id': user.id,
      'service_id': serviceId,
      'booking_date': bookingDate.toIso8601String(),
      'time_slot': timeSlot,
      'status': 'pending',
    });
  }
}
