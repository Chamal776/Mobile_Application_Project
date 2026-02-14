import 'package:projectapp/screens/auth/register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/register_screen.dart';

//Main Function
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tgepucbmayjjquwnoeyn.supabase.co',
    anonKey: 'sb_publishable_4_eO8FxGOQx2pIZw73wyHA_udMxybap',
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    ),
  );
}
