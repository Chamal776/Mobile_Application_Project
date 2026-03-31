import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../data/admin_repository.dart';

class ManageStaffScreen extends ConsumerWidget {
  const ManageStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(allStaffAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Staff',
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showAddSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.softPurple),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: TextStyle(color: AppColors.coralError)),
        ),
        data: (staffList) => staffList.isEmpty
            ? Center(
                child: Text(
                  'No staff added yet.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: staffList.length,
                itemBuilder: (context, i) {
                  final staff = staffList[i];
                  return _StaffCard(
                    data: staff,
                    onToggle: (val) async {
                      await ref
                          .read(adminRepositoryProvider)
                          .toggleStaffAvailability(staff['id'], val);
                      ref.invalidate(allStaffAdminProvider);
                    },
                    onRemove: () => _confirmRemove(context, ref, staff['id']),
                    onManageServices: () =>
                        _showServiceSheet(context, ref, staff),
                  ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.08);
                },
              ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStaffSheet(
        onAdd: (profileId, bio) async {
          await ref.read(adminRepositoryProvider).addStaff(profileId, bio);
          ref.invalidate(allStaffAdminProvider);
        },
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove staff member',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: AppColors.coralError),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminRepositoryProvider).removeStaff(id);
      ref.invalidate(allStaffAdminProvider);
    }
  }

  void _showServiceSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> staff,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceAssignSheet(
        staff: staff,
        onAssign: (serviceId) async {
          await ref
              .read(adminRepositoryProvider)
              .assignServiceToStaff(staff['id'], serviceId);
          ref.invalidate(allStaffAdminProvider);
        },
        onRemove: (serviceId) async {
          await ref
              .read(adminRepositoryProvider)
              .removeServiceFromStaff(staff['id'], serviceId);
          ref.invalidate(allStaffAdminProvider);
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(bool) onToggle;
  final VoidCallback onRemove;
  final VoidCallback onManageServices;

  const _StaffCard({
    required this.data,
    required this.onToggle,
    required this.onRemove,
    required this.onManageServices,
  });

  @override
  Widget build(BuildContext context) {
    final profile = data['profiles'] as Map<String, dynamic>? ?? {};
    final isAvailable = data['is_available'] as bool? ?? true;
    final name = profile['full_name'] as String? ?? 'Staff';
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? AppColors.royalViolet.withOpacity(.2)
              : Colors.white.withOpacity(.04),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isAvailable
                      ? AppColors.primaryGradient
                      : const LinearGradient(
                          colors: [
                            AppColors.cardElevated,
                            AppColors.cardElevated,
                          ],
                        ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: isAvailable ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile['email'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: isAvailable,
                    onChanged: onToggle,
                    activeColor: AppColors.softPurple,
                    activeTrackColor: AppColors.royalViolet.withOpacity(.3),
                    inactiveThumbColor: AppColors.textMuted,
                    inactiveTrackColor: AppColors.cardElevated,
                  ),
                  Text(
                    isAvailable ? 'Available' : 'Off duty',
                    style: TextStyle(
                      color: isAvailable
                          ? AppColors.mintSuccess
                          : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (data['bio'] != null && (data['bio'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepNight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data['bio'],
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManageServices,
                  icon: const Icon(Icons.spa_outlined, size: 16),
                  label: const Text('Services'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.softPurple,
                    side: BorderSide(
                      color: AppColors.royalViolet.withOpacity(.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.person_remove_outlined, size: 16),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coralError,
                    side: BorderSide(
                      color: AppColors.coralError.withOpacity(.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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

class _AddStaffSheet extends ConsumerStatefulWidget {
  final Function(String profileId, String bio) onAdd;

  const _AddStaffSheet({required this.onAdd});

  @override
  ConsumerState<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends ConsumerState<_AddStaffSheet> {
  String? _selectedUserId;
  final _bioCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add staff member',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select user',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            usersAsync.when(
              loading: () =>
                  const CircularProgressIndicator(color: AppColors.softPurple),
              error: (e, _) =>
                  Text('$e', style: TextStyle(color: AppColors.coralError)),
              data: (users) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.deepNight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedUserId,
                    isExpanded: true,
                    hint: const Text(
                      'Choose a registered user',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    dropdownColor: AppColors.cardElevated,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                    ),
                    items: users
                        .where((u) => u['role'] == 'customer')
                        .map(
                          (u) => DropdownMenuItem(
                            value: u['id'] as String,
                            child: Text(
                              '${u['full_name']} (${u['email']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUserId = v),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Bio (optional)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Tell customers about this stylist...',
                fillColor: AppColors.deepNight,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Add to staff',
              isLoading: _isLoading,
              onPressed: _selectedUserId == null
                  ? () {}
                  : () async {
                      setState(() => _isLoading = true);
                      await widget.onAdd(
                        _selectedUserId!,
                        _bioCtrl.text.trim(),
                      );
                      if (mounted) Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceAssignSheet extends ConsumerWidget {
  final Map<String, dynamic> staff;
  final Function(String) onAssign;
  final Function(String) onRemove;

  const _ServiceAssignSheet({
    required this.staff,
    required this.onAssign,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(allServicesAdminProvider);
    final assignedIds = ((staff['staff_services'] as List?) ?? [])
        .map((s) => s['service_id'] as String)
        .toSet();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Services for\n${staff['profiles']?['full_name'] ?? 'Staff'}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          servicesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.softPurple),
            ),
            error: (e, _) =>
                Text('$e', style: TextStyle(color: AppColors.coralError)),
            data: (services) => Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: services.length,
                itemBuilder: (context, i) {
                  final svc = services[i];
                  final isAssigned = assignedIds.contains(svc['id']);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      svc['name'],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      svc['category'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () async {
                        if (isAssigned) {
                          await onRemove(svc['id']);
                        } else {
                          await onAssign(svc['id']);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: isAssigned
                              ? null
                              : AppColors.primaryGradient,
                          color: isAssigned
                              ? AppColors.coralError.withOpacity(.1)
                              : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAssigned ? 'Remove' : 'Assign',
                          style: TextStyle(
                            color: isAssigned
                                ? AppColors.coralError
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
