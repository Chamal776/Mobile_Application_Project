import 'package:flutter/material.dart';

class AppColors {
  static const deepNight = Color(0xFF0D0D1A);
  static const cardSurface = Color(0xFF1A1A2E);
  static const cardElevated = Color(0xFF252545);

  static const royalViolet = Color(0xFF6C3DE8);
  static const softPurple = Color(0xFFA259FF);
  static const blushPink = Color(0xFFFF6B9D);
  static const goldenStar = Color(0xFFFFD166);

  static const mintSuccess = Color(0xFF06D6A0);
  static const coralError = Color(0xFFFF6B6B);
  static const skyInfo = Color(0xFF4CC9F0);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0C8);
  static const textMuted = Color(0xFF6B6B8A);

  static const primaryGradient = LinearGradient(
    colors: [royalViolet, softPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [royalViolet, softPurple, blushPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [softPurple, blushPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warmGradient = LinearGradient(
    colors: [blushPink, goldenStar],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color statusColor(String status) => switch (status) {
    'pending' => textMuted,
    'confirmed' => softPurple,
    'in_progress' => goldenStar,
    'completed' => mintSuccess,
    'cancelled' => coralError,
    _ => textMuted,
  };

  static Color statusBg(String status) => switch (status) {
    'pending' => cardElevated,
    'confirmed' => Color(0x336C3DE8),
    'in_progress' => Color(0x26FFD166),
    'completed' => Color(0x2606D6A0),
    'cancelled' => Color(0x26FF6B6B),
    _ => cardElevated,
  };
}
