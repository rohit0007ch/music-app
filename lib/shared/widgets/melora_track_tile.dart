import 'package:flutter/material.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';

/// Standard list-item tile for a [Track].
class MeloraTrackTile extends StatelessWidget {
  const MeloraTrackTile({
    super.key,
    required this.track,
    this.isPlaying = false,
    this.onTap,
    this.onMore,
    this.trailing,
    this.showDownloadBadge = false,
  });

  final Track track;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final Widget? trailing;
  final bool showDownloadBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                MeloraArtwork(
                  paletteIndex: track.paletteIndex,
                  size: 52,
                  borderRadius: AppSpacing.radiusSm,
                  imageUrl: track.artworkUri,
                ),
                if (isPlaying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        Icons.equalizer_rounded,
                        color: AppColors.accentViolet,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isPlaying
                          ? AppColors.accentVioletLight
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          track.artist,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showDownloadBadge && track.isDownloaded) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.download_done_rounded,
                          size: 12,
                          color: AppColors.accentViolet,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (trailing != null)
              trailing!
            else
              Text(track.durationLabel, style: AppTextStyles.labelMedium),
            if (onMore != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                color: AppColors.textDisabled,
                onPressed: onMore,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
