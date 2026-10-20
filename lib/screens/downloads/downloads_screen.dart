import 'package:flutter/material.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/shared/widgets/melora_empty_state.dart';
import 'package:melora_music/shared/widgets/melora_track_tile.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({
    super.key,
    required this.playerState,
    required this.onTrackTap,
  });

  final PlayerState playerState;
  final void Function(Track) onTrackTap;

  @override
  Widget build(BuildContext context) {
    final downloaded = MockData.downloaded;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text('Downloads', style: AppTextStyles.displayMedium),
                const Spacer(),
                if (downloaded.isNotEmpty)
                  Text(
                    '${downloaded.length} tracks',
                    style: AppTextStyles.bodyMedium,
                  ),
              ],
            ),
          ),
        ),

        if (downloaded.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _StorageCard(trackCount: downloaded.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, i) {
              final t = downloaded[i];
              return ListenableBuilder(
                listenable: playerState,
                builder: (context, _) => MeloraTrackTile(
                  track: t,
                  isPlaying: playerState.currentTrack?.id == t.id,
                  onTap: () => onTrackTap(t),
                  showDownloadBadge: true,
                  onMore: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Track options — coming soon'),
                    ),
                  ),
                ),
              );
            }, childCount: downloaded.length),
          ),
        ] else
          const SliverFillRemaining(
            child: MeloraEmptyState(
              icon: Icons.download_rounded,
              title: 'No downloads yet',
              subtitle:
                  'Downloaded tracks will appear here for offline listening.',
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.trackCount});
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: AppColors.accentViolet,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Storage used', style: AppTextStyles.labelMedium),
                  Text(
                    '$trackCount tracks  · ~'
                    '${(trackCount * 8.4).toStringAsFixed(0)} MB',
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
