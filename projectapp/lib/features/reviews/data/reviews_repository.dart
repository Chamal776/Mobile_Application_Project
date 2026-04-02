import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reviewsRepositoryProvider = Provider((ref) => ReviewsRepository());

final serviceReviewsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      serviceId,
    ) async {
      return ref
          .watch(reviewsRepositoryProvider)
          .getReviewsForService(serviceId);
    });

final staffReviewsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      staffId,
    ) async {
      return ref.watch(reviewsRepositoryProvider).getReviewsForStaff(staffId);
    });

final myReviewsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(reviewsRepositoryProvider).getMyReviews();
});

final averageRatingProvider = FutureProvider.family<double, String>((
  ref,
  staffId,
) async {
  return ref.watch(reviewsRepositoryProvider).getAverageRating(staffId);
});

class ReviewsRepository {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<void> submitReview({
    required String appointmentId,
    required String staffId,
    required int rating,
    required String comment,
  }) async {
    await _client.from('reviews').insert({
      'appointment_id': appointmentId,
      'customer_id': _userId,
      'staff_id': staffId,
      'rating': rating,
      'comment': comment.trim().isEmpty ? null : comment.trim(),
    });
  }

  Future<bool> hasReviewed(String appointmentId) async {
    final data = await _client
        .from('reviews')
        .select('id')
        .eq('appointment_id', appointmentId)
        .eq('customer_id', _userId);
    return (data as List).isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getReviewsForService(
    String serviceId,
  ) async {
    final data = await _client
        .from('reviews')
        .select('''
          *,
          customer:customer_id ( full_name, avatar_url ),
          appointment:appointment_id (
            appointment_services ( service_id )
          )
        ''')
        .order('created_at', ascending: false);

    final all = (data as List).cast<Map<String, dynamic>>();
    return all.where((r) {
      final services = r['appointment']?['appointment_services'] as List? ?? [];
      return services.any((s) => s['service_id'] == serviceId);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getReviewsForStaff(String staffId) async {
    final data = await _client
        .from('reviews')
        .select('''
          *,
          customer:customer_id ( full_name, avatar_url )
        ''')
        .eq('staff_id', staffId)
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMyReviews() async {
    final data = await _client
        .from('reviews')
        .select('''
          *,
          staff:staff_id (
            profiles:profile_id ( full_name )
          ),
          appointment:appointment_id (
            appointment_services (
              services ( name )
            )
          )
        ''')
        .eq('customer_id', _userId)
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<double> getAverageRating(String staffId) async {
    final data = await _client
        .from('reviews')
        .select('rating')
        .eq('staff_id', staffId);
    final list = (data as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return 0.0;
    final sum = list.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
    return sum / list.length;
  }

  Future<Map<String, int>> getRatingBreakdown(String staffId) async {
    final data = await _client
        .from('reviews')
        .select('rating')
        .eq('staff_id', staffId);

    final list = (data as List).cast<Map<String, dynamic>>();

    final Map<String, int> breakdown = {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0};

    for (final r in list) {
      final rating = r['rating'] as int;
      breakdown[rating.toString()] = (breakdown[rating.toString()] ?? 0) + 1;
    }

    return breakdown;
  }
}
