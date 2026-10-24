import 'package:flutter/material.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';

/// Hero artwork with animated scale based on playback state.
class ArtworkHero extends StatelessWidget {
  const ArtworkHero({
    super.key,
    required this.paletteIndex,
    required this.isPlaying,
    this.imageUrl,
  });

  final int paletteIndex;
  final bool isPlaying;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.78;
    return AnimatedScale(
      scale: isPlaying ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: MeloraArtwork(
        paletteIndex: paletteIndex,
        size: size,
        borderRadius: 24,
        imageUrl: imageUrl,
      ),
    );
  }
}
