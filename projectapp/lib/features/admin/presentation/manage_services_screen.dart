import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../data/admin_repository.dart';

class ManageServicesScreen extends ConsumerWidget {
  const ManageServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(allServicesAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Services',
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
              onTap: () => _showForm(context, ref, null),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.softPurple),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: TextStyle(color: AppColors.coralError)),
        ),
        data: (services) => services.isEmpty
            ? Center(
                child: Text(
                  'No services yet. Tap + to add one.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: services.length,
                itemBuilder: (context, i) {
                  final s = services[i];
                  return _ServiceCard(
                    data: s,
                    onEdit: () => _showForm(context, ref, s),
                    onDelete: () => _confirmDelete(context, ref, s['id']),
                    onToggle: (val) async {
                      await ref
                          .read(adminRepositoryProvider)
                          .toggleServiceStatus(s['id'], val);
                      ref.invalidate(allServicesAdminProvider);
                    },
                  ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.08);
                },
              ),
      ),
    );
  }

  void _showForm(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(
        existing: existing,
        onSave: (data) async {
          if (existing == null) {
            await ref.read(adminRepositoryProvider).createService(data);
          } else {
            await ref
                .read(adminRepositoryProvider)
                .updateService(existing['id'], data);
          }
          ref.invalidate(allServicesAdminProvider);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete service',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This action cannot be undone.',
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
              'Delete',
              style: TextStyle(color: AppColors.coralError),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminRepositoryProvider).deleteService(id);
      ref.invalidate(allServicesAdminProvider);
    }
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggle;

  const _ServiceCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = data['is_active'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.royalViolet.withOpacity(.2)
              : Colors.white.withOpacity(.05),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? AppColors.primaryGradient
                      : const LinearGradient(
                          colors: [
                            AppColors.cardElevated,
                            AppColors.cardElevated,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.spa_rounded,
                  color: isActive ? Colors.white : AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'],
                      style: TextStyle(
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['category'] ?? 'No category',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: onToggle,
                activeColor: AppColors.softPurple,
                activeTrackColor: AppColors.royalViolet.withOpacity(.3),
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.cardElevated,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A2A45), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                '\$${(data['price'] as num).toStringAsFixed(0)}',
                Icons.attach_money_rounded,
              ),
              const SizedBox(width: 16),
              _Stat('${data['duration_minutes']} min', Icons.timer_outlined),
              const SizedBox(width: 16),
              _Stat('${data['daily_limit']}/day', Icons.people_outline_rounded),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.softPurple,
                  size: 20,
                ),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 14),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.coralError,
                  size: 20,
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final IconData icon;
  const _Stat(this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 13),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// ── Service form sheet ────────────────────────────────────────────────────────

class _ServiceFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Function(Map<String, dynamic>) onSave;

  const _ServiceFormSheet({this.existing, required this.onSave});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  String _category = 'Hair';
  bool _isLoading = false;

  static const _categories = [
    'Hair',
    'Nails',
    'Skin',
    'Massage',
    'Makeup',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text = e['name'] ?? '';
      _descCtrl.text = e['description'] ?? '';
      _priceCtrl.text = '${e['price'] ?? ''}';
      _durationCtrl.text = '${e['duration_minutes'] ?? ''}';
      _limitCtrl.text = '${e['daily_limit'] ?? ''}';
      _category = e['category'] ?? 'Hair';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

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
            Text(
              isEdit ? 'Edit service' : 'Add new service',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            _Field(
              controller: _nameCtrl,
              label: 'Service name',
              hint: 'e.g. Balayage',
            ),
            _Field(
              controller: _descCtrl,
              label: 'Description',
              hint: 'What does this service include?',
              maxLines: 3,
            ),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _priceCtrl,
                    label: 'Price (\$)',
                    hint: '35',
                    type: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    controller: _durationCtrl,
                    label: 'Duration (min)',
                    hint: '60',
                    type: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    controller: _limitCtrl,
                    label: 'Daily limit',
                    hint: '10',
                    type: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepNight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            dropdownColor: AppColors.cardElevated,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            icon: const Icon(
                              Icons.expand_more_rounded,
                              color: AppColors.textMuted,
                            ),
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ],
            ),
            GradientButton(
              label: isEdit ? 'Save changes' : 'Add service',
              isLoading: _isLoading,
              onPressed: () async {
                if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
                setState(() => _isLoading = true);
                await widget.onSave({
                  'name': _nameCtrl.text.trim(),
                  'description': _descCtrl.text.trim().isEmpty
                      ? null
                      : _descCtrl.text.trim(),
                  'price': double.tryParse(_priceCtrl.text) ?? 0,
                  'duration_minutes': int.tryParse(_durationCtrl.text) ?? 30,
                  'daily_limit': int.tryParse(_limitCtrl.text) ?? 10,
                  'category': _category,
                });
                if (mounted) {
                  setState(() => _isLoading = false);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType type;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.type = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: AppColors.deepNight,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
