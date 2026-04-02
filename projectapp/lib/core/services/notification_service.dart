import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── Initialization ────────────────────────────────────────
  Future<void> initialize() async {
    await _initAwesomeNotifications();
    await _initOneSignal();
  }

  Future<void> _initAwesomeNotifications() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'salon_channel',
        channelName: 'Salon notifications',
        channelDescription: 'Appointment updates and reminders',
        defaultColor: const Color(0xFF6C3DE8),
        ledColor: const Color(0xFFA259FF),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
      ),
      NotificationChannel(
        channelKey: 'reminder_channel',
        channelName: 'Appointment reminders',
        channelDescription: 'Reminders before your appointment',
        defaultColor: const Color(0xFFFF6B9D),
        ledColor: const Color(0xFFFFD166),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
      ),
    ], debug: false);

    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> _initOneSignal() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.none);
    OneSignal.initialize('YOUR_ONESIGNAL_APP_ID');
    await OneSignal.Notifications.requestPermission(true);

    // Save player ID to Supabase when user is logged in
    OneSignal.User.pushSubscription.addObserver((state) async {
      final playerId = state.current.id;
      if (playerId != null) {
        await _savePlayerIdToSupabase(playerId);
      }
    });

    // Handle notification tap when app was closed
    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationTap(event.notification.additionalData ?? {});
    });

    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.preventDefault();
      _showLocalNotification(
        title: event.notification.title ?? 'Salon',
        body: event.notification.body ?? '',
        data: event.notification.additionalData ?? {},
      );
    });
  }

  Future<void> _savePlayerIdToSupabase(String playerId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'onesignal_player_id': playerId})
        .eq('id', userId);
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Navigation logic can be added here based on data
  }

  // ── Local notifications ───────────────────────────────────
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'salon_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: data.map((k, v) => MapEntry(k, v.toString())),
      ),
    );
  }

  Future<void> showAppointmentConfirmed(String serviceName) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'salon_channel',
        title: 'Booking confirmed!',
        body: 'Your $serviceName appointment is confirmed. See you soon!',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> scheduleAppointmentReminder({
    required String serviceName,
    required DateTime appointmentDateTime,
  }) async {
    final reminderTime = appointmentDateTime.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'reminder_channel',
        title: 'Appointment in 1 hour!',
        body: 'Your $serviceName appointment starts soon. Get ready!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: reminderTime,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> showStatusUpdate(String status) async {
    final messages = {
      'confirmed': (
        'Appointment confirmed!',
        'Your booking is confirmed. See you soon!',
      ),
      'in_progress': (
        'Your appointment has started',
        'Your stylist is ready for you.',
      ),
      'completed': (
        'Appointment completed',
        'Thank you for visiting! Leave us a review.',
      ),
      'cancelled': ('Appointment cancelled', 'Your appointment was cancelled.'),
    };

    final msg = messages[status];
    if (msg == null) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'salon_channel',
        title: msg.$1,
        body: msg.$2,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  // ── Realtime listener ─────────────────────────────────────
  void listenToNotifications(String userId) {
    Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((data) async {
          if (data.isEmpty) return;
          final latest = data.first;
          final isRead = latest['is_read'] as bool? ?? true;
          if (!isRead) {
            await _showLocalNotification(
              title: latest['title'] ?? 'Salon',
              body: latest['body'] ?? '',
            );
          }
        });
  }

  // ── Tag user in OneSignal ─────────────────────────────────
  void tagUser(String userId, String role) {
    OneSignal.User.addTagWithKey('user_id', userId);
    OneSignal.User.addTagWithKey('role', role);
  }

  void clearTags() {
    OneSignal.User.removeTag('user_id');
    OneSignal.User.removeTag('role');
  }
}
