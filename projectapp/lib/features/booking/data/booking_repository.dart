import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/appointment_model.dart';

final bookingRepositoryProvider = Provider((ref) => BookingRepository());

final myAppointmentsProvider = FutureProvider<List<AppointmentModel>>((
  ref,
) async {
  return ref.watch(bookingRepositoryProvider).getMyAppointments();
});

final appointmentHistoryProvider = FutureProvider<List<AppointmentModel>>((
  ref,
) async {
  return ref.watch(bookingRepositoryProvider).getAppointmentHistory();
});

class BookingRepository {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<void> createAppointment({
    required String staffId,
    required String date,
    required String time,
    required List<Map<String, dynamic>> services,
    String? notes,
  }) async {
    final appointment = await _client
        .from('appointments')
        .insert({
          'customer_id': _userId,
          'staff_id': staffId,
          'appointment_date': date,
          'appointment_time': time,
          'notes': notes,
          'status': 'pending',
        })
        .select()
        .single();

    final appointmentId = appointment['id'];

    await _client
        .from('appointment_services')
        .insert(
          services
              .map(
                (s) => {
                  'appointment_id': appointmentId,
                  'service_id': s['id'],
                  'price_at_booking': s['price'],
                },
              )
              .toList(),
        );
  }

  Future<List<AppointmentModel>> getMyAppointments() async {
    final data = await _client
        .from('appointments')
        .select('''
          *,
          staff:staff_id (
            profiles:profile_id ( full_name, avatar_url )
          ),
          appointment_services (
            price_at_booking,
            services ( name )
          )
        ''')
        .eq('customer_id', _userId)
        .inFilter('status', ['pending', 'confirmed', 'in_progress'])
        .order('appointment_date');

    return (data as List).map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<List<AppointmentModel>> getAppointmentHistory() async {
    final data = await _client
        .from('appointments')
        .select('''
          *,
          staff:staff_id (
            profiles:profile_id ( full_name, avatar_url )
          ),
          appointment_services (
            price_at_booking,
            services ( name )
          )
        ''')
        .eq('customer_id', _userId)
        .inFilter('status', ['completed', 'cancelled'])
        .order('appointment_date', ascending: false);

    return (data as List).map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<void> cancelAppointment(String id) async {
    await _client
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }
}
