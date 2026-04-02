import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationsRepositoryProvider = Provider(
  (ref) => NotificationsRepository(),
);

final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(notificationsRepositoryProvider).watchNotifications();
});

final unreadCountProvider = StreamProvider<int>((ref) {
  return ref.watch(notificationsRepositoryProvider).watchUnreadCount();
});

class NotificationsRepository {
  final _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Stream<List<Map<String, dynamic>>> watchNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  Stream<int> watchUnreadCount() {
    return watchNotifications().map(
      (notifications) =>
          notifications.where((n) => n['is_read'] == false).length,
    );
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  Future<void> clearAll() async {
    await _client.from('notifications').delete().eq('user_id', _userId);
  }
}
