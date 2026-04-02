import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Supabase.initialize(
    url: 'https://uumcomtsjumqgzmkhylj.supabase.co',
    anonKey: 'sb_publishable_qcm558f0Y5vC--GUWXkeKQ_A9hll8lN',
  );

  await NotificationService().initialize();

  runApp(const ProviderScope(child: SalonApp()));
}
