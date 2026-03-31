import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/appointment_status_badge.dart';
import '../data/admin_repository.dart';

final _filterProvider = StateProvider<String>((ref) => 'all');

class ManageAppointmentsScreen extends ConsumerWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(allAppointmentsProvider);
    final filter = ref.watch(_filterProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Appointments',
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
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children:
                  [
                    'all',
                    'pending',
                    'confirmed',
                    'in_progress',
                    'completed',
                    'cancelled',
                  ].map((s) {
                    final isSelected = filter == s;
                    return GestureDetector(
                      onTap: () => ref.read(_filterProvider.notifier).state = s,
                      child: AnimatedContainer(
                        duration: 200.ms,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppColors.primaryGradient
                              : null,
                          color: isSelected ? null : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          s == 'all' ? 'All' : s.replaceAll('_', ' '),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: apptAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.softPurple),
              ),
              error: (e, _) => Center(
                child: Text(
                  '$e',
                  style: TextStyle(color: AppColors.coralError),
                ),
              ),
              data: (appts) {
                final filtered = filter == 'all'
                    ? appts
                    : appts.where((a) => a['status'] == filter).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No appointments found',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    return _AppointmentCard(
                      data: filtered[i],
                      onStatusChange: (status) async {
                        await ref
                            .read(adminRepositoryProvider)
                            .updateAppointmentStatus(filtered[i]['id'], status);
                        ref.invalidate(allAppointmentsProvider);
                        ref.invalidate(adminStatsProvider);
                      },
                    ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.08);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String) onStatusChange;

  const _AppointmentCard({required this.data, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final staff = data['staff'];
    final staffName = staff?['profiles']?['full_name'] ?? 'Unassigned';
    final services = data['appointment_services'] as List? ?? [];
    final serviceNames = services
        .map((s) => s['services']['name'] as String)
        .join(', ');
    final totalPrice = services.fold<double>(
      0,
      (sum, s) => sum + (s['price_at_booking'] as num).toDouble(),
    );
    final status = data['status'] as String;
    final date = DateTime.parse(data['appointment_date']);
    final dateStr = DateFormat('EEE, MMM d').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.statusColor(status).withOpacity(.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (customer['full_name'] as String? ?? 'U')
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join(),
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
                      customer['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      customer['phone'] ?? customer['email'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              AppointmentStatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF2A2A45), height: 1),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.spa_outlined,
                  label: 'Service',
                  value: serviceNames,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Stylist',
                  value: staffName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: dateStr,
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: data['appointment_time'] ?? '',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF2A2A45), height: 1),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.heroGradient.createShader(b),
                child: Text(
                  '\$${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status,
                    isDense: true,
                    dropdownColor: AppColors.cardElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                    items:
                        [
                              'pending',
                              'confirmed',
                              'in_progress',
                              'completed',
                              'cancelled',
                            ]
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: AppColors.statusColor(s),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) onStatusChange(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
