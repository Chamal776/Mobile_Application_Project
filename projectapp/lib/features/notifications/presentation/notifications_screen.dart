import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Notifications',
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
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllAsRead();
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.softPurple, fontSize: 13),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.softPurple),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: TextStyle(color: AppColors.coralError)),
        ),
        data: (notifications) => notifications.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: notifications.length,
                itemBuilder: (context, i) {
                  return _NotificationCard(
                        data: notifications[i],
                        onTap: () async {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .markAsRead(notifications[i]['id']);
                        },
                        onDismiss: () async {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .deleteNotification(notifications[i]['id']);
                        },
                      )
                      .animate()
                      .fadeIn(delay: (i * 60).ms)
                      .slideX(begin: 0.1, end: 0);
                },
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.data,
    required this.onTap,
    required this.onDismiss,
  });

  IconData get _icon => switch (data['type'] as String? ?? '') {
    'appointment_confirmed' => Icons.check_circle_outline_rounded,
    'appointment_reminder' => Icons.alarm_rounded,
    'appointment_cancelled' => Icons.cancel_outlined,
    'status_update' => Icons.update_rounded,
    _ => Icons.notifications_outlined,
  };

  Color get _iconColor => switch (data['type'] as String? ?? '') {
    'appointment_confirmed' => AppColors.mintSuccess,
    'appointment_reminder' => AppColors.goldenStar,
    'appointment_cancelled' => AppColors.coralError,
    'status_update' => AppColors.softPurple,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final isRead = data['is_read'] as bool? ?? false;
    final createdAt = DateTime.parse(data['created_at']);
    final timeStr = _formatTime(createdAt);

    return Dismissible(
      key: Key(data['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.coralError.withOpacity(.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.coralError,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? AppColors.cardSurface
                : AppColors.royalViolet.withOpacity(.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRead
                  ? Colors.transparent
                  : AppColors.royalViolet.withOpacity(.3),
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconColor.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? '',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['body'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread dot
              if (!isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.textMuted,
              size: 36,
            ),
          ).animate().scale(duration: 400.ms),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          const Text(
            'You\'ll be notified about your\nappointment updates here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
