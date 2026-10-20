import 'package:flutter/material.dart';
import 'package:melora_music/data/mock/mock_data.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/shared/widgets/melora_chip.dart';
import 'package:melora_music/shared/widgets/melora_empty_state.dart';
import 'package:melora_music/shared/widgets/melora_search_bar.dart';
import 'package:melora_music/shared/widgets/melora_track_tile.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.playerState,
    required this.onTrackTap,
  });

  final PlayerState playerState;
  final void Function(Track) onTrackTap;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedGenre = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Track> get _filteredTracks => MockData.tracks.where((t) {
    final matchesQuery =
        _query.isEmpty ||
        t.title.toLowerCase().contains(_query.toLowerCase()) ||
        t.artist.toLowerCase().contains(_query.toLowerCase());
    final matchesGenre = _selectedGenre == 'All' || t.genre == _selectedGenre;
    return matchesQuery && matchesGenre;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTracks;
    final isSearching = _query.isNotEmpty || _selectedGenre != 'All';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: CustomScrollView(
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
                    onChanged: (q) => setState(() => _query = q),
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
                      onTap: () => setState(() => _selectedGenre = g),
                    );
                  },
                ),
              ),
            ),
          ),

          if (!isSearching) ...[
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _MoodCard(mood: MockData.moods[i]),
                  childCount: MockData.moods.length,
                ),
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
                child: Text('Trending Now', style: AppTextStyles.headlineLarge),
              ),
            ),
          ],

          if (filtered.isEmpty)
            SliverFillRemaining(
              child: MeloraEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No results found',
                subtitle: 'Try a different search term or genre.',
                action: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _selectedGenre = 'All';
                  });
                },
                actionLabel: 'Clear filters',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final t = filtered[i];
                return ListenableBuilder(
                  listenable: widget.playerState,
                  builder: (context, _) => MeloraTrackTile(
                    track: t,
                    isPlaying: widget.playerState.currentTrack?.id == t.id,
                    onTap: () => widget.onTrackTap(t),
                  ),
                );
              }, childCount: filtered.length),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood});
  final Map<String, dynamic> mood;

  @override
  Widget build(BuildContext context) {
    final idx = mood['paletteIndex'] as int;
    final palette =
        AppColors.artworkPalettes[idx % AppColors.artworkPalettes.length];
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${mood['label']} playlist coming soon')),
      ),
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
