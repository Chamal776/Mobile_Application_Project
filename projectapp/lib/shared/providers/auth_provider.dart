import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/notification_service.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_user_model.dart';

final authStateProvider = StreamProvider((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProfileProvider = FutureProvider<AuthUserModel?>((ref) async {
  return ref.watch(authRepositoryProvider).getCurrentUser();
});

final userRoleProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  return profile?.role ?? 'customer';
});

final notificationSetupProvider = Provider((ref) {
  ref.listen(authStateProvider, (_, next) {
    next.whenData((event) {
      final user = event.session?.user;
      if (user != null) {
        NotificationService().listenToNotifications(user.id);
        ref.read(currentUserProfileProvider.future).then((profile) {
          if (profile != null) {
            NotificationService().tagUser(user.id, profile.role);
          }
        });
      } else {
        NotificationService().clearTags();
      }
    });
  });
});
