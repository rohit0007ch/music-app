import 'package:flutter/material.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';

/// Displays a gradient placeholder artwork square/rectangle.
class MeloraArtwork extends StatelessWidget {
  const MeloraArtwork({
    super.key,
    required this.paletteIndex,
    this.size = AppSpacing.artworkCardSize,
    this.borderRadius = AppSpacing.radiusMd,
  });

  final int paletteIndex;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors
        .artworkPalettes[paletteIndex % AppColors.artworkPalettes.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: palette[0].withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.35),
          size: size * 0.35,
        ),
      ),
    );
  }
}
