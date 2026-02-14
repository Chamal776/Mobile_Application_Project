import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';

class ServiceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ServiceModel>> fetchServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ServiceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception("Failed to load services: $e");
    }
  }
}
