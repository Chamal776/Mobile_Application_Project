import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: AppColors.cardElevated);
  }
}

class ShimmerServiceCard extends StatelessWidget {
  const ShimmerServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoader(height: 100, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoader(width: 100, height: 12, borderRadius: 6),
                const SizedBox(height: 6),
                ShimmerLoader(width: 60, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerAppointmentCard extends StatelessWidget {
  const ShimmerAppointmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoader(width: 140, height: 14, borderRadius: 6),
              ShimmerLoader(width: 70, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerLoader(width: 200, height: 12, borderRadius: 6),
          const SizedBox(height: 8),
          const ShimmerLoader(width: 160, height: 12, borderRadius: 6),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerLoader(width: 50, height: 18, borderRadius: 6),
              ShimmerLoader(width: 90, height: 32, borderRadius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class ShimmerListLoader extends StatelessWidget {
  final int count;

  const ShimmerListLoader({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (i) => const ShimmerAppointmentCard()),
    );
  }
}
