import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../data/reviews_repository.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String staffId;
  final String staffName;
  final String serviceName;
  final DateTime appointmentDate;

  const ReviewScreen({
    super.key,
    required this.appointmentId,
    required this.staffId,
    required this.staffName,
    required this.serviceName,
    required this.appointmentDate,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  final List<String> _quickTags = [
    'Great service',
    'Very professional',
    'Loved the result',
    'Will come back',
    'Highly recommend',
    'Exceeded expectations',
  ];

  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String get _ratingLabel => switch (_rating) {
    1 => 'Poor',
    2 => 'Fair',
    3 => 'Good',
    4 => 'Very good',
    5 => 'Excellent!',
    _ => 'Tap to rate',
  };

  Color get _ratingColor => switch (_rating) {
    1 => AppColors.coralError,
    2 => const Color(0xFFFF9F43),
    3 => AppColors.goldenStar,
    4 => AppColors.softPurple,
    5 => AppColors.mintSuccess,
    _ => AppColors.textMuted,
  };

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a rating'),
          backgroundColor: AppColors.goldenStar,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tags = _selectedTags.isNotEmpty ? _selectedTags.join(', ') : '';
      final fullComment = [
        tags,
        _commentCtrl.text.trim(),
      ].where((s) => s.isNotEmpty).join('\n');

      await ref
          .read(reviewsRepositoryProvider)
          .submitReview(
            appointmentId: widget.appointmentId,
            staffId: widget.staffId,
            rating: _rating,
            comment: fullComment,
          );

      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: AppColors.coralError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Leave a review',
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
      body: _submitted
          ? _SuccessView(onDone: () => Navigator.pop(context))
          : _FormView(
              rating: _rating,
              ratingLabel: _ratingLabel,
              ratingColor: _ratingColor,
              commentCtrl: _commentCtrl,
              quickTags: _quickTags,
              selectedTags: _selectedTags,
              isLoading: _isLoading,
              staffName: widget.staffName,
              serviceName: widget.serviceName,
              appointmentDate: widget.appointmentDate,
              onRatingChanged: (r) => setState(() => _rating = r.toInt()),
              onTagToggle: (tag) => setState(() {
                if (_selectedTags.contains(tag)) {
                  _selectedTags.remove(tag);
                } else {
                  _selectedTags.add(tag);
                }
              }),
              onSubmit: _submit,
            ),
    );
  }
}

class _FormView extends StatelessWidget {
  final int rating;
  final String ratingLabel;
  final Color ratingColor;
  final TextEditingController commentCtrl;
  final List<String> quickTags;
  final Set<String> selectedTags;
  final bool isLoading;
  final String staffName;
  final String serviceName;
  final DateTime appointmentDate;
  final Function(double) onRatingChanged;
  final Function(String) onTagToggle;
  final VoidCallback onSubmit;

  const _FormView({
    required this.rating,
    required this.ratingLabel,
    required this.ratingColor,
    required this.commentCtrl,
    required this.quickTags,
    required this.selectedTags,
    required this.isLoading,
    required this.staffName,
    required this.serviceName,
    required this.appointmentDate,
    required this.onRatingChanged,
    required this.onTagToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appointment summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      staffName
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
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
                        staffName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        serviceName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMMM d, y').format(appointmentDate),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          const SizedBox(height: 32),

          // Rating stars
          Center(
            child: Column(
              children: [
                const Text(
                  'How was your experience?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                RatingBar.builder(
                  initialRating: rating.toDouble(),
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 6),
                  itemSize: 48,
                  itemBuilder: (context, _) => ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.warmGradient.createShader(bounds),
                    child: const Icon(Icons.star_rounded, color: Colors.white),
                  ),
                  unratedColor: AppColors.cardElevated,
                  onRatingUpdate: onRatingChanged,
                ),
                const SizedBox(height: 12),
                AnimatedDefaultTextStyle(
                  duration: 200.ms,
                  style: TextStyle(
                    color: ratingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Text(ratingLabel),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 32),

          // Quick tags
          const Text(
            'Quick tags',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => onTagToggle(tag),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(.08),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        tag,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 28),

          // Written comment
          const Text(
            'Write a comment',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(.06),
                width: 0.5,
              ),
            ),
            child: TextField(
              controller: commentCtrl,
              maxLines: 5,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText: 'Tell us more about your experience...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 32),

          GradientButton(
            label: 'Submit review',
            isLoading: isLoading,
            onPressed: onSubmit,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;

  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(),

            const SizedBox(height: 28),

            const Text(
              'Thank you!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

            const SizedBox(height: 12),

            const Text(
              'Your review helps us improve\nand serve you better.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 40),

            // Rating display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Icon(
                      Icons.star_rounded,
                      color: AppColors.goldenStar,
                      size: 32,
                    )
                    .animate()
                    .scale(
                      delay: (500 + i * 80).ms,
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(delay: (500 + i * 80).ms);
              }),
            ),

            const SizedBox(height: 40),

            GradientButton(
              label: 'Done',
              onPressed: onDone,
            ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
