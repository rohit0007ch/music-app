import 'package:flutter/material.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/favorites_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Toggles [track] in [favoritesState], syncs player flags, and surfaces errors.
///
/// Returns `true` when the store updated successfully.
Future<bool> toggleFavoriteTrack({
  required BuildContext context,
  required Track track,
  required FavoritesState favoritesState,
  required PlayerState playerState,
}) async {
  if (favoritesState.saving) return false;

  final ok = await favoritesState.toggle(track);
  playerState.syncFavouriteFlags(favoritesState.isFavorite);
  if (!context.mounted) return ok;
  if (!ok) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            favoritesState.error ?? 'Could not update favorites.',
          ),
        ),
      );
  }
  return ok;
}

/// Compact list row for add/remove favourite sheets.
class FavoriteToggleTile extends StatelessWidget {
  const FavoriteToggleTile({
    super.key,
    required this.track,
    required this.favoritesState,
    required this.playerState,
    this.onCompleted,
  });

  final Track track;
  final FavoritesState favoritesState;
  final PlayerState playerState;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favoritesState,
      builder: (context, _) {
        final isFavourite = favoritesState.isFavorite(track.id);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isFavourite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isFavourite
                ? AppColors.accentAmber
                : AppColors.textSecondary,
          ),
          title: Text(
            isFavourite ? 'Remove from favourites' : 'Add to favourites',
            style: AppTextStyles.titleMedium,
          ),
          enabled: !favoritesState.saving,
          onTap: () async {
            final ok = await toggleFavoriteTrack(
              context: context,
              track: track,
              favoritesState: favoritesState,
              playerState: playerState,
            );
            if (ok && context.mounted) {
              onCompleted?.call();
            }
          },
        );
      },
    );
  }
}

/// Simple bottom sheet with track title and a favourite toggle.
Future<void> showFavoriteTrackSheet({
  required BuildContext context,
  required Track track,
  required FavoritesState favoritesState,
  required PlayerState playerState,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text(track.artist, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FavoriteToggleTile(
              track: track,
              favoritesState: favoritesState,
              playerState: playerState,
              onCompleted: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      );
    },
  );
}
