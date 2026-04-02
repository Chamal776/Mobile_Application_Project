import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/appointment_status_badge.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/domain/appointment_model.dart';
import '../../notifications/presentation/notifications_screen.dart';

class CustomerDashboard extends ConsumerWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final upcomingAsync = ref.watch(myAppointmentsProvider);
    final historyAsync = ref.watch(appointmentHistoryProvider);
    final name = user?.userMetadata?['full_name'] ?? 'Guest';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.split(' ').map((e) => e[0]).take(2).join(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My account',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),
                  // Stats row
                  upcomingAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (upcoming) => historyAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (history) => Row(
                        children: [
                          _StatCard(
                            label: 'Upcoming',
                            value: '${upcoming.length}',
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Completed',
                            value:
                                '${history.where((a) => a.status == 'completed').length}',
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Total visits',
                            value: '${upcoming.length + history.length}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Upcoming appointments
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'Upcoming appointments',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          SliverToBoxAdapter(
            child: upcomingAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.softPurple),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: AppColors.coralError),
                ),
              ),
              data: (appointments) => appointments.isEmpty
                  ? _EmptyState(
                      icon: Icons.calendar_today_outlined,
                      message: 'No upcoming appointments',
                      sub: 'Book a service to get started',
                    )
                  : Column(
                      children: appointments
                          .asMap()
                          .entries
                          .map(
                            (e) =>
                                AppointmentCard(
                                      appointment: e.value,
                                      onCancel: () => _cancelAppointment(
                                        context,
                                        ref,
                                        e.value.id,
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: (e.key * 80).ms)
                                    .slideY(begin: 0.1),
                          )
                          .toList(),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // History
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'History',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          SliverToBoxAdapter(
            child: historyAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.softPurple),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: AppColors.coralError),
                ),
              ),
              data: (appointments) => appointments.isEmpty
                  ? _EmptyState(
                      icon: Icons.history_rounded,
                      message: 'No history yet',
                      sub: 'Your past appointments will appear here',
                    )
                  : Column(
                      children: appointments
                          .asMap()
                          .entries
                          .map(
                            (e) => AppointmentCard(
                              appointment: e.value,
                              showReview: e.value.status == 'completed',
                            ).animate().fadeIn(delay: (e.key * 80).ms),
                          )
                          .toList(),
                    ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
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
          'Are you sure you want to cancel?',
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

    if (confirm == true) {
      await ref.read(bookingRepositoryProvider).cancelAppointment(id);
      ref.invalidate(myAppointmentsProvider);
    }
  }
}

class AppointmentCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                      onPressed: () {},
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
                      onPressed: onCancel,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
