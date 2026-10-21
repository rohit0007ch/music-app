import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/shared/widgets/melora_chip.dart';
import 'package:melora_music/shared/widgets/melora_empty_state.dart';
import 'package:melora_music/shared/widgets/melora_search_bar.dart';
import 'package:melora_music/shared/widgets/melora_track_tile.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/discover_catalog_state.dart';
import 'package:melora_music/viewmodels/player_state.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.playerState,
    required this.onTrackTap,
    this.catalogState,
  });

  final PlayerState playerState;
  final Future<void> Function(Track track, {List<Track>? queueContext})
  onTrackTap;

  /// Optional override for tests.
  final DiscoverCatalogState? catalogState;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  late final DiscoverCatalogState _catalog;
  late final bool _ownsCatalog;
  String _selectedGenre = 'All';

  @override
  void initState() {
    super.initState();
    _ownsCatalog = widget.catalogState == null;
    _catalog = widget.catalogState ?? DiscoverCatalogState();
    _catalog.loadPopular();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsCatalog) {
      _catalog.dispose();
    }
    super.dispose();
  }

  void _submitSearch(String value) {
    FocusScope.of(context).unfocus();
    setState(() => _selectedGenre = 'All');
    _catalog.search(value);
  }

  void _selectGenre(String genre) {
    setState(() => _selectedGenre = genre);
    _searchController.clear();
    if (genre == 'All') {
      _catalog.loadPopular();
    } else {
      _catalog.loadTags(_jamendoTagForGenre(genre));
    }
  }

  void _selectMood(String label) {
    setState(() => _selectedGenre = 'All');
    _searchController.clear();
    _catalog.loadTags(_jamendoTagForMood(label));
  }

  void _showTrackInfo(Track track) {
    final license = track.licenseUrl?.trim();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
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
              if (track.album.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(track.album, style: AppTextStyles.labelMedium),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'Catalog metadata from Jamendo. A license URL does not mean '
                'this track is cleared for commercial use.',
                style: AppTextStyles.bodyMedium,
              ),
              if (license != null && license.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('License', style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                SelectableText(license, style: AppTextStyles.bodyMedium),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: license));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('License URL copied')),
                        );
                      }
                    },
                    child: const Text('Copy license URL'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListenableBuilder(
        listenable: _catalog,
        builder: (context, _) {
          final showBrowseChrome = !_catalog.isFiltered;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Discover', style: AppTextStyles.displayMedium),
                      const SizedBox(height: AppSpacing.md),
                      MeloraSearchBar(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: _submitSearch,
                      ),
                    ],
                  ),
                ),
              ),

              // Genre chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: MockData.genres.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final g = MockData.genres[i];
                        return MeloraChip(
                          label: g,
                          isSelected: _selectedGenre == g,
                          onTap: () => _selectGenre(g),
                        );
                      },
                    ),
                  ),
                ),
              ),

              if (showBrowseChrome) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      'Browse by Mood',
                      style: AppTextStyles.headlineLarge,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 2.4,
                        ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final mood = MockData.moods[i];
                      return _MoodCard(
                        mood: mood,
                        onTap: () => _selectMood(mood['label'] as String),
                      );
                    }, childCount: MockData.moods.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      _catalog.activeQuery.isEmpty ? 'Trending Now' : 'Results',
                      style: AppTextStyles.headlineLarge,
                    ),
                  ),
                ),
              ] else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      _catalog.activeQuery.isNotEmpty
                          ? 'Results'
                          : 'Tagged tracks',
                      style: AppTextStyles.headlineLarge,
                    ),
                  ),
                ),

              ..._buildBodySlivers(),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    if (_catalog.loading) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_catalog.needsConfig || _catalog.errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MeloraEmptyState(
            icon: _catalog.needsConfig
                ? Icons.settings_suggest_rounded
                : Icons.cloud_off_rounded,
            title: _catalog.needsConfig
                ? 'Catalog not configured'
                : 'Couldn’t load music',
            subtitle: _catalog.errorMessage,
            actionLabel: _catalog.needsConfig ? null : 'Retry',
            action: _catalog.needsConfig ? null : _catalog.retry,
          ),
        ),
      ];
    }

    if (!_catalog.hasTracks) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MeloraEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No results found',
            subtitle: 'Try a different search term, genre, or mood.',
            action: () {
              _searchController.clear();
              setState(() => _selectedGenre = 'All');
              _catalog.loadPopular();
            },
            actionLabel: 'Show trending',
          ),
        ),
      ];
    }

    final tracks = _catalog.tracks;
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          final t = tracks[i];
          return ListenableBuilder(
            listenable: widget.playerState,
            builder: (context, _) => MeloraTrackTile(
              track: t,
              isPlaying: widget.playerState.currentTrack?.id == t.id,
              onTap: () => widget.onTrackTap(t, queueContext: tracks),
              onMore: () => _showTrackInfo(t),
            ),
          );
        }, childCount: tracks.length),
      ),
    ];
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood, required this.onTap});
  final Map<String, dynamic> mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final idx = mood['paletteIndex'] as int;
    final palette =
        AppColors.artworkPalettes[idx % AppColors.artworkPalettes.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: LinearGradient(
            colors: [palette[0], palette[1]],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                mood['icon'] as String,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                mood['label'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _jamendoTagForGenre(String genre) {
  switch (genre) {
    case 'Hip-Hop':
      return 'hiphop';
    case 'R&B':
      return 'rnb';
    case 'Lofi':
      return 'lofi';
    default:
      return genre.toLowerCase();
  }
}

String _jamendoTagForMood(String label) {
  switch (label) {
    case 'Energetic':
      return 'energetic';
    case 'Chill':
      return 'chill';
    case 'Focus':
      return 'focus';
    case 'Happy':
      return 'happy';
    case 'Melancholy':
      return 'melancholy';
    case 'Romantic':
      return 'romantic';
    default:
      return label.toLowerCase();
  }
}
