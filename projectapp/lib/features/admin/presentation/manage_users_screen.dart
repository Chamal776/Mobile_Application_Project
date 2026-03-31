import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_repository.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Manage admins',
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
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.royalViolet.withOpacity(.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.royalViolet.withOpacity(.3),
                width: 0.5,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.softPurple,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Promote customers to admin to give them full salon management access.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.softPurple),
              ),
              error: (e, _) => Center(
                child: Text(
                  '$e',
                  style: TextStyle(color: AppColors.coralError),
                ),
              ),
              data: (users) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  final isSelf = user['id'] == currentUserId;
                  final role = user['role'] as String;
                  final isAdmin = role == 'admin' || role == 'super_admin';
                  final isSuperAdmin = role == 'super_admin';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isAdmin
                            ? AppColors.royalViolet.withOpacity(.25)
                            : Colors.transparent,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: isAdmin
                                ? AppColors.heroGradient
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
                              (user['full_name'] as String? ?? 'U')
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .take(2)
                                  .join(),
                              style: TextStyle(
                                color: isAdmin
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name + email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user['full_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelf) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.royalViolet
                                            .withOpacity(.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'You',
                                        style: TextStyle(
                                          color: AppColors.softPurple,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (isSuperAdmin) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: AppColors.goldenStar,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user['email'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action button
                        if (!isSelf && !isSuperAdmin)
                          GestureDetector(
                            onTap: () async {
                              if (isAdmin) {
                                await ref
                                    .read(adminRepositoryProvider)
                                    .demoteToCustomer(user['id']);
                              } else {
                                await ref
                                    .read(adminRepositoryProvider)
                                    .promoteToAdmin(user['id']);
                              }
                              ref.invalidate(allUsersProvider);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: isAdmin
                                    ? null
                                    : AppColors.primaryGradient,
                                color: isAdmin
                                    ? AppColors.coralError.withOpacity(.1)
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAdmin ? 'Demote' : 'Make admin',
                                style: TextStyle(
                                  color: isAdmin
                                      ? AppColors.coralError
                                      : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (i * 50).ms);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
