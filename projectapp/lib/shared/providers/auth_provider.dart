import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/notification_service.dart';

final authStateProvider = StreamProvider((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();

  return data;
});

final userRoleProvider = FutureProvider<String>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  return profile?['role'] as String? ?? 'customer';
});

// Watches auth state and sets up notifications automatically
final notificationSetupProvider = Provider((ref) {
  ref.listen(authStateProvider, (_, next) {
    next.whenData((event) {
      final user = event.session?.user;
      if (user != null) {
        // Start listening to realtime notifications
        NotificationService().listenToNotifications(user.id);

        // Tag user in OneSignal
        ref.read(currentUserProfileProvider.future).then((profile) {
          if (profile != null) {
            NotificationService().tagUser(
              user.id,
              profile['role'] as String? ?? 'customer',
            );
          }
        });
      } else {
        // User signed out — clear OneSignal tags
        NotificationService().clearTags();
      }
    });
  });
});
