import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const deepNight = Color(0xFF0D0D1A);
  static const cardSurface = Color(0xFF1A1A2E);
  static const cardElevated = Color(0xFF252545);

  // Brand
  static const royalViolet = Color(0xFF6C3DE8);
  static const softPurple = Color(0xFFA259FF);
  static const blushPink = Color(0xFFFF6B9D);
  static const goldenStar = Color(0xFFFFD166);

  // Semantic
  static const mintSuccess = Color(0xFF06D6A0);
  static const coralError = Color(0xFFFF6B6B);
  static const skyInfo = Color(0xFF4CC9F0);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0C8);
  static const textMuted = Color(0xFF6B6B8A);

  // Gradients
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

  // Status colors
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
    'confirmed' => royalViolet.withOpacity(.2),
    'in_progress' => goldenStar.withOpacity(.15),
    'completed' => mintSuccess.withOpacity(.15),
    'cancelled' => coralError.withOpacity(.15),
    _ => cardElevated,
  };
}
