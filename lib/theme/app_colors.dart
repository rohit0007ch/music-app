import 'package:flutter/material.dart';

/// Melora design-system colour tokens.
abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceElevated = Color(0xFF1C1C28);
  static const Color border = Color(0xFF2A2A3A);

  // Accent – Electric Violet
  static const Color accentViolet = Color(0xFF7C4DFF);
  static const Color accentVioletLight = Color(0xFFB388FF);
  static const Color accentVioletDark = Color(0xFF5C35CC);

  // Accent – Amber (favourites)
  static const Color accentAmber = Color(0xFFFFB300);

  // Text
  static const Color textPrimary = Color(0xFFF0EEF8);
  static const Color textSecondary = Color(0xFF9891B8);
  static const Color textDisabled = Color(0xFF504E6A);

  // Semantic
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF69F0AE);

  /// Artwork placeholder gradient palettes — indexed by [Track.paletteIndex].
  static const List<List<Color>> artworkPalettes = [
    [Color(0xFF7C4DFF), Color(0xFF1A0066)],
    [Color(0xFFE91E8C), Color(0xFF4A0030)],
    [Color(0xFF00BCD4), Color(0xFF003040)],
    [Color(0xFFFF6D00), Color(0xFF3E1000)],
    [Color(0xFF43A047), Color(0xFF0A2A0A)],
    [Color(0xFFD500F9), Color(0xFF2D003F)],
    [Color(0xFF2979FF), Color(0xFF001A4A)],
    [Color(0xFFFF1744), Color(0xFF3E0010)],
  ];
}
