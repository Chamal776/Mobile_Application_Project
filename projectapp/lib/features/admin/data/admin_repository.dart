import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());

final allAppointmentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(adminRepositoryProvider).getAllAppointments();
});

final allServicesAdminProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(adminRepositoryProvider).getAllServices();
});

final allStaffAdminProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(adminRepositoryProvider).getAllStaff();
});

final allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDashboardStats();
});

class AdminRepository {
  final _client = Supabase.instance.client;

  // ── Dashboard stats ───────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final total = await _client
        .from('appointments')
        .select('id')
        .count(CountOption.exact);

    final todayCount = await _client
        .from('appointments')
        .select('id')
        .eq('appointment_date', today)
        .count(CountOption.exact);

    final pending = await _client
        .from('appointments')
        .select('id')
        .eq('status', 'pending')
        .count(CountOption.exact);

    final customers = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'customer')
        .count(CountOption.exact);

    return {
      'total': total.count,
      'today': todayCount.count,
      'pending': pending.count,
      'customers': customers.count,
    };
  }

  // ── Appointments ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    final data = await _client
        .from('appointments')
        .select('''
          *,
          customer:customer_id ( full_name, phone, email ),
          staff:staff_id (
            profiles:profile_id ( full_name )
          ),
          appointment_services (
            price_at_booking,
            services ( name )
          )
        ''')
        .order('appointment_date', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _client.from('appointments').update({'status': status}).eq('id', id);
  }

  // ── Services ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllServices() async {
    final data = await _client.from('services').select().order('created_at');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> createService(Map<String, dynamic> data) async {
    await _client.from('services').insert(data);
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _client.from('services').update(data).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await _client.from('services').delete().eq('id', id);
  }

  Future<void> toggleServiceStatus(String id, bool isActive) async {
    await _client.from('services').update({'is_active': isActive}).eq('id', id);
  }

  // ── Staff ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllStaff() async {
    final data = await _client
        .from('staff')
        .select('''
          *,
          profiles:profile_id ( full_name, email, avatar_url, phone ),
          staff_services ( service_id )
        ''')
        .order('created_at');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> addStaff(String profileId, String bio) async {
    await _client.from('staff').insert({
      'profile_id': profileId,
      'bio': bio,
      'is_available': true,
    });
  }

  Future<void> toggleStaffAvailability(String id, bool isAvailable) async {
    await _client
        .from('staff')
        .update({'is_available': isAvailable})
        .eq('id', id);
  }

  Future<void> removeStaff(String id) async {
    await _client.from('staff').delete().eq('id', id);
  }

  Future<void> assignServiceToStaff(String staffId, String serviceId) async {
    await _client.from('staff_services').insert({
      'staff_id': staffId,
      'service_id': serviceId,
    });
  }

  Future<void> removeServiceFromStaff(String staffId, String serviceId) async {
    await _client
        .from('staff_services')
        .delete()
        .eq('staff_id', staffId)
        .eq('service_id', serviceId);
  }

  // ── Users ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final data = await _client.from('profiles').select().order('created_at');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> promoteToAdmin(String userId) async {
    await _client.from('profiles').update({'role': 'admin'}).eq('id', userId);
  }

  Future<void> demoteToCustomer(String userId) async {
    await _client
        .from('profiles')
        .update({'role': 'customer'})
        .eq('id', userId);
  }
}
