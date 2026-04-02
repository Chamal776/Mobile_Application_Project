import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../features/reviews/presentation/reviews_list_screen.dart';

class StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final VoidCallback? onTap;
  final bool showReviews;

  const StaffCard({
    super.key,
    required this.staff,
    this.onTap,
    this.showReviews = true,
  });

  String _getName() {
    try {
      final profile = staff['profile'];
      if (profile is Map<String, dynamic>) {
        final name = profile['full_name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
      final profiles = staff['profiles'];
      if (profiles is Map<String, dynamic>) {
        final name = profiles['full_name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
      if (profiles is List && profiles.isNotEmpty) {
        final first = profiles.first;
        if (first is Map<String, dynamic>) {
          final name = first['full_name'] as String?;
          if (name != null && name.isNotEmpty) return name;
        }
      }
      return 'Stylist';
    } catch (_) {
      return 'Stylist';
    }
  }

  String? _getAvatarUrl() {
    try {
      final profile = staff['profile'];
      if (profile is Map<String, dynamic>) {
        return profile['avatar_url'] as String?;
      }
      final profiles = staff['profiles'];
      if (profiles is Map<String, dynamic>) {
        return profiles['avatar_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool get _isAvailable => staff['is_available'] as bool? ?? true;

  String _getInitials(String name) {
    return name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final name = _getName();
    final avatarUrl = _getAvatarUrl();
    final initials = _getInitials(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isAvailable
                ? AppColors.royalViolet.withOpacity(.2)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _isAvailable
                        ? AppColors.primaryGradient
                        : const LinearGradient(
                            colors: [
                              AppColors.cardElevated,
                              AppColors.cardElevated,
                            ],
                          ),
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
                                style: TextStyle(
                                  color: _isAvailable
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: _isAvailable
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
                if (_isAvailable)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.mintSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cardSurface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name.split(' ').first,
              style: TextStyle(
                color: _isAvailable
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (showReviews)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewsListScreen(
                      staffId: staff['id'],
                      staffName: name,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.royalViolet.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: AppColors.goldenStar,
                        size: 11,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Reviews',
                        style: TextStyle(
                          color: AppColors.softPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

class StaffHorizontalList extends StatelessWidget {
  final List<Map<String, dynamic>> staffList;

  const StaffHorizontalList({super.key, required this.staffList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: staffList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          return StaffCard(
            staff: staffList[i],
          ).animate().fadeIn(delay: (i * 80).ms);
        },
      ),
    );
  }
}
