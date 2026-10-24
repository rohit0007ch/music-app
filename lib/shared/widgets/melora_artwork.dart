import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';

/// Displays gradient placeholder artwork, optionally overlaid with an image.
///
/// Supports HTTPS (online catalog), `file://` (local album art cache), and
/// Flutter asset paths (`assets/…`). Missing, invalid, or unloadable URIs
/// fall back to the gradient.
class MeloraArtwork extends StatelessWidget {
  const MeloraArtwork({
    super.key,
    required this.paletteIndex,
    this.size = AppSpacing.artworkCardSize,
    this.borderRadius = AppSpacing.radiusMd,
    this.imageUrl,
  });

  final int paletteIndex;
  final double size;
  final double borderRadius;

  /// Optional artwork URI (`https://…` or `file://…`). Null/empty keeps gradient.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors
        .artworkPalettes[paletteIndex % AppColors.artworkPalettes.length];
    final image = _buildOverlayImage();

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
      clipBehavior: Clip.antiAlias,
      child: image ?? _PlaceholderIcon(size: size),
    );
  }

  Widget? _buildOverlayImage() {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    // Bundled Flutter assets (featured artwork, etc.).
    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _PlaceholderIcon(size: size),
      );
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme.isEmpty) return null;

    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return Image.network(
        raw,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _PlaceholderIcon(size: size),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _PlaceholderIcon(size: size);
        },
      );
    }

    // Local album art is cached as file:// by the platform channel.
    // Skip on web — dart:io File is unavailable there.
    if (scheme == 'file' && !kIsWeb) {
      try {
        final file = File.fromUri(uri);
        if (!file.existsSync()) {
          return null;
        }
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, _, _) => _PlaceholderIcon(size: size),
        );
      } on Object {
        return null;
      }
    }

    // content:// and other schemes are not loaded here — gradient fallback.
    return null;
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.white.withValues(alpha: 0.35),
        size: size * 0.35,
      ),
    );
  }
}
