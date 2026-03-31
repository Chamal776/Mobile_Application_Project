import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'shared/providers/auth_provider.dart';

class SalonApp extends ConsumerWidget {
  const SalonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationSetupProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Glamour Salon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
