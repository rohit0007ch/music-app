import 'package:flutter/material.dart';
import 'package:melora_music/data/models/lyrics.dart';
import 'package:melora_music/shared/widgets/melora_empty_state.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/lyrics_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Bottom sheet for lyrics lookup + display for the current track.
class LyricsSheet extends StatefulWidget {
  const LyricsSheet({super.key, required this.playerState, this.lyricsState});

  final PlayerState playerState;

  /// Optional override for tests.
  final LyricsState? lyricsState;

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  late final LyricsState _lyrics;
  late final bool _ownsLyrics;
  int _lastActiveIndex = -1;
  ScrollController? _activeScroll;

  @override
  void initState() {
    super.initState();
    _ownsLyrics = widget.lyricsState == null;
    _lyrics = widget.lyricsState ?? LyricsState();
    widget.playerState.addListener(_onPlayerChanged);
    _lyrics.loadForTrack(widget.playerState.currentTrack);
  }

  @override
  void dispose() {
    widget.playerState.removeListener(_onPlayerChanged);
    if (_ownsLyrics) _lyrics.dispose();
    super.dispose();
  }

  void _onPlayerChanged() {
    final track = widget.playerState.currentTrack;
    if (track?.id != _lyrics.trackId) {
      _lyrics.loadForTrack(track);
      _lastActiveIndex = -1;
    }
  }

  void _maybeScrollToActive(int activeIndex) {
    final controller = _activeScroll;
    if (controller == null || !controller.hasClients) return;
    if (activeIndex < 0 || activeIndex == _lastActiveIndex) return;
    _lastActiveIndex = activeIndex;
    final offset = (activeIndex * 36.0).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );
    controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sheetScroll) {
        _activeScroll = sheetScroll;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text('Lyrics', style: AppTextStyles.headlineMedium),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: widget.playerState,
                      builder: (context, _) => Flexible(
                        child: Text(
                          widget.playerState.currentTrack?.title ?? '',
                          style: AppTextStyles.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListenableBuilder(
                  listenable: _lyrics,
                  builder: (context, _) => _buildBody(sheetScroll),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController sheetScroll) {
    switch (_lyrics.status) {
      case LyricsStatus.idle:
      case LyricsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LyricsStatus.unavailable:
        return MeloraEmptyState(
          icon: Icons.lyrics_outlined,
          title: 'Lyrics unavailable',
          subtitle:
              _lyrics.errorMessage ??
              'No matching lyrics were found for this track.',
        );
      case LyricsStatus.error:
        return MeloraEmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Couldn’t load lyrics',
          subtitle: _lyrics.errorMessage,
          actionLabel: 'Retry',
          action: () => _lyrics.retry(widget.playerState.currentTrack),
        );
      case LyricsStatus.ready:
        final result = _lyrics.result!;
        if (result.isInstrumental && result.lines.isEmpty) {
          return const MeloraEmptyState(
            icon: Icons.music_note_rounded,
            title: 'Instrumental track',
            subtitle: 'This track has no lyrics.',
          );
        }
        return _LyricsList(
          result: result,
          playerState: widget.playerState,
          scrollController: sheetScroll,
          onActiveChanged: _maybeScrollToActive,
        );
    }
  }
}

class _LyricsList extends StatelessWidget {
  const _LyricsList({
    required this.result,
    required this.playerState,
    required this.scrollController,
    required this.onActiveChanged,
  });

  final LyricsResult result;
  final PlayerState playerState;
  final ScrollController scrollController;
  final ValueChanged<int> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Text(
            result.hasTimedLines
                ? 'Synced lyrics via ${result.sourceName}'
                : 'Lyrics via ${result.sourceName}',
            style: AppTextStyles.labelMedium,
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: playerState,
            builder: (context, _) {
              final active = result.activeLineIndex(playerState.position);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onActiveChanged(active);
              });

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                itemCount: result.lines.length,
                itemBuilder: (context, index) {
                  final line = result.lines[index];
                  if (line.text.isEmpty) {
                    return const SizedBox(height: 12);
                  }
                  final isSection = RegExp(
                    r'^\[[^\]]+\]$',
                  ).hasMatch(line.text.trim());
                  final isHighlighted = result.hasTimedLines && index == active;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: isSection ? 10 : 6),
                    child: Text(
                      line.text,
                      style: isSection
                          ? AppTextStyles.titleMedium.copyWith(
                              color: AppColors.accentVioletLight,
                              letterSpacing: 0.6,
                            )
                          : isHighlighted
                          ? AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.accentVioletLight,
                            )
                          : AppTextStyles.bodyLarge.copyWith(
                              color: result.hasTimedLines
                                  ? AppColors.textDisabled
                                  : AppColors.textPrimary,
                              height: 1.45,
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
