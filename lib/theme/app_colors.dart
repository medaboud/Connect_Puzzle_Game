import 'package:flutter/material.dart';

/// Palette defining the visual identity of Loopline.
/// Based on warm off-white, deep ink, cobalt path, and coral accents.
class AppColors {
  const AppColors._();

  // Core Brand Colors
  static const Color background = Color(0xFFF9F7F2); // Warm off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textInk = Color(0xFF191F28); // Deep ink
  static const Color textMuted = Color(0xFF6B7280); // Subtle ink
  static const Color textLight = Color(0xFF9CA3AF);

  // Gameplay Accent Colors
  static const Color cobaltPath = Color(0xFF2563EB); // Vibrant cobalt
  static const Color cobaltHead = Color(0xFF1D4ED8); // Active head
  static const Color cobaltLight = Color(0xFFDBEAFE);

  static const Color coralCheckpoint = Color(0xFFEF4444); // Coral accent
  static const Color coralCheckpointDark = Color(0xFFDC2626);
  static const Color coralLight = Color(0xFFFEE2E2);

  static const Color completedGreen = Color(0xFF10B981);
  static const Color hintGold = Color(0xFFF59E0B);
  static const Color invalidRed = Color(0xFFE11D48);

  // Board & Grid
  static const Color cellBackground = Color(0xFFF1EFEA);
  static const Color cellBorder = Color(0xFFE5E2D9);
  static const Color cellActive = Color(0xFFEFF6FF);

  // Dark Mode Alternatives
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkTextInk = Color(0xFFF9FAFB);
  static const Color darkTextMuted = Color(0xFF9CA3AF);
  static const Color darkCellBackground = Color(0xFF1E293B);
  static const Color darkCellBorder = Color(0xFF334155);
}
