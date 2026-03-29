import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/service_model.dart';

final servicesRepositoryProvider = Provider((ref) => ServicesRepository());

final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  return ref.watch(servicesRepositoryProvider).getActiveServices();
});

final servicesByCategoryProvider =
    FutureProvider.family<List<ServiceModel>, String>((ref, category) async {
      return ref.watch(servicesRepositoryProvider).getByCategory(category);
    });

class ServicesRepository {
  final _client = Supabase.instance.client;

  Future<List<ServiceModel>> getActiveServices() async {
    final data = await _client
        .from('services')
        .select()
        .eq('is_active', true)
        .order('created_at');
    return (data as List).map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<List<ServiceModel>> getByCategory(String category) async {
    final query = _client.from('services').select().eq('is_active', true);

    final data = category == 'All'
        ? await query.order('created_at')
        : await query.eq('category', category).order('created_at');

    return (data as List).map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<bool> checkSlotAvailability(
    String serviceId,
    String date,
    String time,
  ) async {
    final data = await _client.rpc(
      'check_daily_limit',
      params: {'p_service_id': serviceId, 'p_date': date, 'p_time': time},
    );
    return data as bool;
  }
}
