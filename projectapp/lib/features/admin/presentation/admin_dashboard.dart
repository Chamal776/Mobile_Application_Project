import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_repository.dart';
import 'manage_appointments_screen.dart';
import 'manage_services_screen.dart';
import 'manage_staff_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;

  final _screens = const [
    _AdminHomeTab(),
    ManageAppointmentsScreen(),
    ManageServicesScreen(),
    ManageStaffScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(.06), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.softPurple,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.spa_outlined),
              activeIcon: Icon(Icons.spa_rounded),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Staff',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _AdminHomeTab extends ConsumerWidget {
  const _AdminHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final firstName =
        user?.userMetadata?['full_name']?.toString().split(' ').first ??
        'Admin';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin panel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hi, $firstName 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideX(begin: -0.1),
                      Row(
                        children: [
                          _IconBtn(
                            icon: Icons.admin_panel_settings_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageUsersScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _IconBtn(
                            icon: Icons.logout_rounded,
                            onTap: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Stats row
                  statsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (stats) => Row(
                      children: [
                        _StatTile(
                          label: 'Today',
                          value: '${stats['today']}',
                          icon: Icons.today_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Pending',
                          value: '${stats['pending']}',
                          icon: Icons.pending_actions_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Customers',
                          value: '${stats['customers']}',
                          icon: Icons.people_rounded,
                        ),
                        const SizedBox(width: 10),
                        _StatTile(
                          label: 'Total',
                          value: '${stats['total']}',
                          icon: Icons.bar_chart_rounded,
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'Quick actions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.4,
              ),
              delegate: SliverChildListDelegate([
                _QuickCard(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Add service',
                      sub: 'Create new service',
                      gradient: AppColors.primaryGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageServicesScreen(),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 250.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
                _QuickCard(
                      icon: Icons.calendar_month_rounded,
                      label: 'Appointments',
                      sub: 'Manage bookings',
                      gradient: AppColors.accentGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageAppointmentsScreen(),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
                _QuickCard(
                      icon: Icons.people_rounded,
                      label: 'Manage staff',
                      sub: 'Add or edit staff',
                      gradient: AppColors.warmGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageStaffScreen(),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 350.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
                _QuickCard(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Manage admins',
                      sub: 'Promote users',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06D6A0), Color(0xFF6C3DE8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageUsersScreen(),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // Recent appointments
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'Recent appointments',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          SliverToBoxAdapter(
            child: appointmentsAsync.when(
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
                final recent = appts.take(5).toList();
                return Column(
                  children: recent.asMap().entries.map((e) {
                    return _RecentTile(
                          data: e.value,
                          onStatusChange: (status) async {
                            await ref
                                .read(adminRepositoryProvider)
                                .updateAppointmentStatus(e.value['id'], status);
                            ref.invalidate(allAppointmentsProvider);
                            ref.invalidate(adminStatsProvider);
                          },
                        )
                        .animate()
                        .fadeIn(delay: (e.key * 80).ms)
                        .slideY(begin: 0.1);
                  }).toList(),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(String) onStatusChange;

  const _RecentTile({required this.data, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final services = data['appointment_services'] as List? ?? [];
    final serviceNames = services
        .map((s) => s['services']['name'] as String)
        .join(', ');
    final status = data['status'] as String;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
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
                  fontSize: 13,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  serviceNames,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusDropdown(status: status, onChanged: onStatusChange),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String status;
  final Function(String) onChanged;

  const _StatusDropdown({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusBg(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          isDense: true,
          dropdownColor: AppColors.cardElevated,
          style: TextStyle(
            color: AppColors.statusColor(status),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            color: AppColors.statusColor(status),
            size: 14,
          ),
          items:
              ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.replaceAll('_', ' '),
                        style: TextStyle(
                          color: AppColors.statusColor(s),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
