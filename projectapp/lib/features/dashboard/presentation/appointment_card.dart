import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/appointment_status_badge.dart';
import '../../booking/domain/appointment_model.dart';
import '../../booking/data/booking_repository.dart';
import '../../reviews/presentation/review_screen.dart';

class AppointmentCard extends ConsumerWidget {
  final AppointmentModel appointment;
  final VoidCallback? onCancel;
  final bool showReview;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
    this.showReview = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat(
      'EEE, MMM d',
    ).format(appointment.appointmentDate);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.statusColor(appointment.status).withOpacity(.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row — service name + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  appointment.serviceNames.join(', '),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppointmentStatusBadge(status: appointment.status),
            ],
          ),

          const SizedBox(height: 12),

          // Info chips row
          Row(
            children: [
              _InfoChip(icon: Icons.calendar_today_outlined, label: dateStr),
              const SizedBox(width: 10),
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: appointment.appointmentTime,
              ),
            ],
          ),

          if (appointment.staffName != null) ...[
            const SizedBox(height: 8),
            _InfoChip(
              icon: Icons.person_outline_rounded,
              label: appointment.staffName!,
            ),
          ],

          const SizedBox(height: 12),

          // Bottom row — price + action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.heroGradient.createShader(b),
                child: Text(
                  '\$${appointment.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: [
                  if (showReview)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            appointmentId: appointment.id,
                            staffId: appointment.staffId ?? '',
                            staffName: appointment.staffName ?? 'Your stylist',
                            serviceName: appointment.serviceNames.isNotEmpty
                                ? appointment.serviceNames.first
                                : 'Service',
                            appointmentDate: appointment.appointmentDate,
                          ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        backgroundColor: AppColors.royalViolet.withOpacity(.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Leave review',
                        style: TextStyle(
                          color: AppColors.softPurple,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (onCancel != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _confirmCancel(context, ref),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        backgroundColor: AppColors.coralError.withOpacity(.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.coralError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel appointment',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, cancel',
              style: TextStyle(color: AppColors.coralError),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && onCancel != null) {
      onCancel!();
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
