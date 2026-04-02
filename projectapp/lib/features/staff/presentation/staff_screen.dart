import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../reviews/presentation/reviews_list_screen.dart';

final staffListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final data = await Supabase.instance.client
      .from('staff')
      .select('id, bio, is_available, profile_id')
      .eq('is_available', true)
      .order('created_at');

  final staffList = (data as List).cast<Map<String, dynamic>>();

  final enriched = <Map<String, dynamic>>[];

  for (final staff in staffList) {
    final profileId = staff['profile_id'];
    if (profileId == null) {
      enriched.add({...staff, 'profile': {}});
      continue;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, email, avatar_url, phone')
          .eq('id', profileId)
          .single();

      final services = await Supabase.instance.client
          .from('staff_services')
          .select('services(name, category)')
          .eq('staff_id', staff['id']);

      enriched.add({
        ...staff,
        'profile': profile as Map<String, dynamic>,
        'service_list': (services as List).cast<Map<String, dynamic>>(),
      });
    } catch (_) {
      enriched.add({...staff, 'profile': {}});
    }
  }

  return enriched;
});

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Our stylists',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.softPurple),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: TextStyle(color: AppColors.coralError)),
        ),
        data: (staffList) => staffList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.cardSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_outline_rounded,
                        color: AppColors.textMuted,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No stylists available',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Check back soon!',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: staffList.length,
                itemBuilder: (context, i) {
                  return _StaffCard(
                    data: staffList[i],
                  ).animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.1);
                },
              ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _StaffCard({super.key, required this.data});

  String _getName() {
    try {
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        final name = profile['full_name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
      return 'Stylist';
    } catch (_) {
      return 'Stylist';
    }
  }

  String? _getAvatarUrl() {
    try {
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        return profile['avatar_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _getEmail() {
    try {
      final profile = data['profile'];
      if (profile is Map<String, dynamic>) {
        return profile['email'] as String? ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  List<String> _getServiceNames() {
    try {
      final services = data['service_list'] as List? ?? [];
      return services
          .map((s) {
            final svc = s['services'];
            if (svc is Map<String, dynamic>) {
              return svc['name'] as String? ?? '';
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _getInitials(String name) {
    return name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final name = _getName();
    final avatarUrl = _getAvatarUrl();
    final email = _getEmail();
    final serviceNames = _getServiceNames();
    final initials = _getInitials(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.royalViolet.withOpacity(.15),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintSuccess.withOpacity(.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(
                          color: AppColors.mintSuccess,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Reviews button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReviewsListScreen(staffId: data['id'], staffName: name),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Reviews',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (data['bio'] != null && (data['bio'] as String).isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepNight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data['bio'],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],

          if (serviceNames.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF2A2A45), height: 1),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: serviceNames.map((svc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.royalViolet.withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      svc,
                      style: const TextStyle(
                        color: AppColors.softPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
