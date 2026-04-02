import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../booking/data/booking_repository.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';
import 'appointment_card.dart';

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                name
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .take(2)
                                    .join(),
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
                      ),
                      // Bell icon
                      Consumer(
                        builder: (context, ref, _) {
                          final unreadAsync = ref.watch(unreadCountProvider);
                          final count = unreadAsync.value ?? 0;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.blushPink,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),
                  // Stats
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

          // Upcoming title
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
              loading: () => const ShimmerListLoader(count: 2),
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

          // History title
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
              loading: () => const ShimmerListLoader(count: 2),
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
              decoration: const BoxDecoration(
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
