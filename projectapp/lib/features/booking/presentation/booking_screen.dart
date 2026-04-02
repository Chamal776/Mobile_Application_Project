import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../services/domain/service_model.dart';
import 'booking_confirm_screen.dart';

final _selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final _selectedTimeProvider = StateProvider<String?>((ref) => null);
final _selectedStaffProvider = StateProvider<Map<String, dynamic>?>(
  (ref) => null,
);

const _timeSlots = [
  '09:00',
  '10:00',
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
];

class BookingScreen extends ConsumerStatefulWidget {
  final ServiceModel service;

  const BookingScreen({super.key, required this.service});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  List<Map<String, dynamic>> _staffList = [];
  bool _loadingStaff = true;
  String? _staffError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_selectedTimeProvider.notifier).state = null;
      ref.read(_selectedStaffProvider.notifier).state = null;
    });
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      setState(() {
        _loadingStaff = true;
        _staffError = null;
      });

      // Query staff with explicit join to profiles
      final data = await Supabase.instance.client
          .from('staff')
          .select('''
            id,
            bio,
            is_available,
            profile_id,
            staff_services!inner ( service_id )
          ''')
          .eq('is_available', true)
          .eq('staff_services.service_id', widget.service.id);

      if (!mounted) return;

      final staffList = (data as List).cast<Map<String, dynamic>>();

      // Now fetch profiles separately for each staff
      final enrichedList = await _enrichWithProfiles(staffList);

      if (enrichedList.isEmpty) {
        // Fallback — get all available staff
        final allData = await Supabase.instance.client
            .from('staff')
            .select('''
              id,
              bio,
              is_available,
              profile_id
            ''')
            .eq('is_available', true);

        if (!mounted) return;

        final allList = (allData as List).cast<Map<String, dynamic>>();
        final allEnriched = await _enrichWithProfiles(allList);

        if (!mounted) return;
        setState(() {
          _staffList = allEnriched;
          _loadingStaff = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _staffList = enrichedList;
          _loadingStaff = false;
        });
      }
    } catch (e) {
      debugPrint('Staff load error: $e');
      if (!mounted) return;
      setState(() {
        _staffError = e.toString();
        _loadingStaff = false;
      });
    }
  }

  // Fetch profiles separately and attach to staff records
  Future<List<Map<String, dynamic>>> _enrichWithProfiles(
    List<Map<String, dynamic>> staffList,
  ) async {
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

        enriched.add({...staff, 'profile': profile as Map<String, dynamic>});
      } catch (_) {
        enriched.add({...staff, 'profile': {}});
      }
    }

    return enriched;
  }

  String _getStaffName(Map<String, dynamic> staff) {
    try {
      // Try our new 'profile' key first
      final profile = staff['profile'];
      if (profile is Map<String, dynamic>) {
        final name = profile['full_name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }

      // Fallback to 'profiles' key (old format)
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

  Map<String, dynamic> _getStaffProfileMap(Map<String, dynamic> staff) {
    try {
      final profile = staff['profile'];
      if (profile is Map<String, dynamic> && profile.isNotEmpty) {
        return profile;
      }
      final profiles = staff['profiles'];
      if (profiles is Map<String, dynamic>) return profiles;
      if (profiles is List && profiles.isNotEmpty) {
        final first = profiles.first;
        if (first is Map<String, dynamic>) return first;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  String _getInitials(String name) {
    return name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(_selectedDateProvider);
    final selectedTime = ref.watch(_selectedTimeProvider);
    final selectedStaff = ref.watch(_selectedStaffProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Book appointment',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.service.durationMinutes} min · \$${widget.service.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 28),

            // Calendar
            _SectionTitle('Choose date'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: selectedDate,
                selectedDayPredicate: (d) => isSameDay(d, selectedDate),
                onDaySelected: (selected, _) =>
                    ref.read(_selectedDateProvider.notifier).state = selected,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: AppColors.royalViolet.withOpacity(.4),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.royalViolet, AppColors.softPurple],
                    ),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                  weekendTextStyle: const TextStyle(color: AppColors.textMuted),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayTextStyle: const TextStyle(color: Colors.white),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppColors.textSecondary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  weekendStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 28),

            // Time slots
            _SectionTitle('Choose time'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.map((time) {
                final isSelected = time == selectedTime;
                return GestureDetector(
                  onTap: () =>
                      ref.read(_selectedTimeProvider.notifier).state = time,
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.accentGradient : null,
                      color: isSelected ? null : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: Colors.white.withOpacity(.08),
                              width: 0.5,
                            ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 28),

            // Staff selection
            _SectionTitle('Choose stylist'),
            const SizedBox(height: 12),

            if (_loadingStaff)
              const Center(
                child: CircularProgressIndicator(color: AppColors.softPurple),
              )
            else if (_staffError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.coralError.withOpacity(.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.coralError,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Could not load stylists. Tap to retry.',
                        style: TextStyle(
                          color: AppColors.coralError,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadStaff,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_staffList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'No stylists available right now.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _staffList.map((staff) {
                  final name = _getStaffName(staff);
                  final profile = _getStaffProfileMap(staff);
                  final isSelected = selectedStaff?['id'] == staff['id'];
                  final avatarUrl = profile['avatar_url'] as String?;

                  return GestureDetector(
                    onTap: () =>
                        ref.read(_selectedStaffProvider.notifier).state = staff,
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.softPurple
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
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
                                          _getInitials(name),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(name),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
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
                                if (staff['bio'] != null &&
                                    (staff['bio'] as String).isNotEmpty)
                                  Text(
                                    staff['bio'],
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
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            GradientButton(
              label: 'Continue',
              onPressed: () {
                if (selectedTime == null) {
                  _showWarning('Please select a time');
                  return;
                }
                if (selectedStaff == null && _staffList.isNotEmpty) {
                  _showWarning('Please select a stylist');
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingConfirmScreen(
                      service: widget.service,
                      date: selectedDate,
                      time: selectedTime!,
                      staff:
                          selectedStaff ??
                          (_staffList.isNotEmpty ? _staffList.first : {}),
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.goldenStar,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 17,
      ),
    );
  }
}
