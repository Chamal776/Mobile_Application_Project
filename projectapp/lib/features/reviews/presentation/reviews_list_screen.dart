import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/reviews_repository.dart';

class ReviewsListScreen extends ConsumerWidget {
  final String staffId;
  final String staffName;

  const ReviewsListScreen({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(staffReviewsProvider(staffId));
    final avgAsync = ref.watch(averageRatingProvider(staffId));

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '$staffName\'s reviews',
          style: const TextStyle(
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
      body: reviewsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.softPurple),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: TextStyle(color: AppColors.coralError)),
        ),
        data: (reviews) => CustomScrollView(
          slivers: [
            // Rating summary header
            SliverToBoxAdapter(
              child: avgAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (avg) => _RatingSummary(
                  average: avg,
                  totalReviews: reviews.length,
                  staffId: staffId,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            reviews.isEmpty
                ? SliverToBoxAdapter(child: _EmptyReviews())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ReviewCard(
                        data: reviews[i],
                      ).animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.1),
                      childCount: reviews.length,
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _RatingSummary extends ConsumerWidget {
  final double average;
  final int totalReviews;
  final String staffId;

  const _RatingSummary({
    required this.average,
    required this.totalReviews,
    required this.staffId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Big average number
          Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.warmGradient.createShader(b),
                child: Text(
                  average.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              RatingBarIndicator(
                rating: average,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star_rounded, color: AppColors.goldenStar),
                itemCount: 5,
                itemSize: 18,
                unratedColor: AppColors.cardElevated,
              ),
              const SizedBox(height: 6),
              Text(
                '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),
          const VerticalDivider(color: Color(0xFF2A2A45), width: 1),
          const SizedBox(width: 24),

          // Breakdown bars
          Expanded(
            child: FutureBuilder<Map<String, int>>(
              future: ref
                  .read(reviewsRepositoryProvider)
                  .getRatingBreakdown(staffId),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final breakdown = snap.data!;
                return Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = breakdown[star] ?? 0;
                    final pct = totalReviews > 0 ? count / totalReviews : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.goldenStar,
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: AppColors.cardElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  star >= 4
                                      ? AppColors.mintSuccess
                                      : star == 3
                                      ? AppColors.goldenStar
                                      : AppColors.coralError,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ReviewCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final name = customer['full_name'] as String? ?? 'Anonymous';
    final rating = data['rating'] as int;
    final comment = data['comment'] as String?;
    final createdAt = DateTime.parse(data['created_at']);
    final dateStr = DateFormat('MMM d, y').format(createdAt);
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < rating
                        ? AppColors.goldenStar
                        : AppColors.cardElevated,
                    size: 18,
                  );
                }),
              ),
            ],
          ),

          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF2A2A45), height: 1),
            const SizedBox(height: 14),

            // Tags row (first line if contains tags)
            if (comment.contains('\n')) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: comment
                    .split('\n')
                    .first
                    .split(', ')
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.royalViolet.withOpacity(.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: AppColors.softPurple,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text(
                comment.split('\n').skip(1).join('\n'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ] else
              Text(
                comment,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
          ],

          const SizedBox(height: 12),

          // Rating label pill
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _ratingBg(rating),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _ratingText(rating),
                style: TextStyle(
                  color: _ratingFg(rating),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingText(int r) => switch (r) {
    5 => 'Excellent',
    4 => 'Very good',
    3 => 'Good',
    2 => 'Fair',
    _ => 'Poor',
  };

  Color _ratingBg(int r) => switch (r) {
    5 => AppColors.mintSuccess.withOpacity(.15),
    4 => AppColors.softPurple.withOpacity(.15),
    3 => AppColors.goldenStar.withOpacity(.15),
    2 => const Color(0xFFFF9F43).withOpacity(.15),
    _ => AppColors.coralError.withOpacity(.15),
  };

  Color _ratingFg(int r) => switch (r) {
    5 => AppColors.mintSuccess,
    4 => AppColors.softPurple,
    3 => AppColors.goldenStar,
    2 => const Color(0xFFFF9F43),
    _ => AppColors.coralError,
  };
}

class _EmptyReviews extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_border_rounded,
                color: AppColors.textMuted,
                size: 36,
              ),
            ).animate().scale(duration: 400.ms),
            const SizedBox(height: 16),
            const Text(
              'No reviews yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 6),
            const Text(
              'Be the first to leave a review!',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
