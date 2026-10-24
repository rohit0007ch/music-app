import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:melora_music/data/featured/featured_song.dart';
import 'package:melora_music/screens/now_playing/sheets/lyrics_sheet.dart';
import 'package:melora_music/shared/widgets/melora_artwork.dart';
import 'package:melora_music/theme/app_colors.dart';
import 'package:melora_music/theme/app_spacing.dart';
import 'package:melora_music/theme/app_text_styles.dart';
import 'package:melora_music/viewmodels/player_state.dart';

/// Premium featured-song card for Dinesh Dalla only.
///
/// Idle state runs soft pre-play decorations (orbit rings, shimmer, equalizer
/// tease). Playing state pulses with the shared [PlayerState].
class FeaturedSongCard extends StatefulWidget {
  const FeaturedSongCard({
    super.key,
    required this.playerState,
    required this.onPlay,
  });

  final PlayerState playerState;
  final Future<void> Function() onPlay;

  @override
  State<FeaturedSongCard> createState() => FeaturedSongCardState();
}

@visibleForTesting
class FeaturedSongCardState extends State<FeaturedSongCard>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _pulseController;
  late final AnimationController _idleController;
  late final AnimationController _orbitController;
  late final AnimationController _introController;
  late final AnimationController _launchController;

  bool get _isCurrent =>
      FeaturedSong.isFeaturedId(widget.playerState.currentTrack?.id);

  bool get _isPlayingFeatured => _isCurrent && widget.playerState.isPlaying;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    );
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _launchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    widget.playerState.addListener(_syncAnimations);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAnimations();
      if (!MediaQuery.disableAnimationsOf(context)) {
        _introController.forward();
      } else {
        _introController.value = 1;
      }
    });
  }

  @override
  void didUpdateWidget(covariant FeaturedSongCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerState != widget.playerState) {
      oldWidget.playerState.removeListener(_syncAnimations);
      widget.playerState.addListener(_syncAnimations);
      _syncAnimations();
    }
  }

  @override
  void dispose() {
    widget.playerState.removeListener(_syncAnimations);
    _glowController.dispose();
    _pulseController.dispose();
    _idleController.dispose();
    _orbitController.dispose();
    _introController.dispose();
    _launchController.dispose();
    super.dispose();
  }

  void _syncAnimations() {
    if (!mounted) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final playing = _isPlayingFeatured;

    if (reduceMotion) {
      _glowController.stop();
      _glowController.value = 0.35;
      _pulseController.stop();
      _pulseController.value = 0;
      _idleController.stop();
      _idleController.value = 0.4;
      _orbitController.stop();
      _orbitController.value = 0;
      return;
    }

    if (!_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    }
    if (!_orbitController.isAnimating) {
      _orbitController.repeat();
    }

    if (playing) {
      _idleController.stop();
      _idleController.value = 0;
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      if (!_idleController.isAnimating) {
        _idleController.repeat(reverse: true);
      }
    }
  }

  Future<void> _onPlayPause() async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_isCurrent && !reduceMotion) {
      // Short “ignition” flourish before the shared player starts.
      await _launchController.forward(from: 0);
      if (mounted) _launchController.reverse();
    }
    if (_isCurrent) {
      await widget.playerState.togglePlayPause();
      return;
    }
    await widget.onPlay();
  }

  void _openLyrics(BuildContext context) {
    if (!_isCurrent) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Play Dinesh Dalla first to view lyrics.'),
          ),
        );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LyricsSheet(playerState: widget.playerState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = FeaturedSong.track;
    final palette = AppColors
        .artworkPalettes[track.paletteIndex % AppColors.artworkPalettes.length];

    return ListenableBuilder(
      listenable: widget.playerState,
      builder: (context, _) {
        final playing = _isPlayingFeatured;
        return AnimatedBuilder(
          animation: Listenable.merge([
            _glowController,
            _pulseController,
            _idleController,
            _orbitController,
            _introController,
            _launchController,
          ]),
          builder: (context, child) {
            final glowT = _glowController.value;
            final idleT = _idleController.value;
            final intro = Curves.easeOutCubic.transform(_introController.value);
            final launch = Curves.easeOutBack.transform(
              _launchController.value,
            );
            final pulse = 1.0 + (_pulseController.value * 0.035);
            final idleBreath = 1.0 + (idleT * 0.012);
            final launchPop = 1.0 + (launch * 0.05);
            final scale = (playing ? pulse : idleBreath) * launchPop;
            final glowAlpha = playing
                ? 0.28 + (glowT * 0.32)
                : 0.16 + (idleT * 0.22);
            final borderAlpha = playing
                ? 0.45 + (glowT * 0.4)
                : 0.28 + (idleT * 0.35);

            return Opacity(
              opacity: intro.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - intro) * 18),
                child: Transform.scale(
                  scale: scale * (0.96 + intro * 0.04),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentViolet.withValues(
                            alpha: glowAlpha,
                          ),
                          blurRadius: playing ? 30 : 20 + idleT * 10,
                          spreadRadius: playing ? 1.5 : idleT * 0.8,
                        ),
                        if (!playing)
                          BoxShadow(
                            color: AppColors.accentVioletLight.withValues(
                              alpha: 0.08 + idleT * 0.1,
                            ),
                            blurRadius: 36,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Stack(
                        children: [
                          // Base gradient surface
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusLg,
                                ),
                                border: Border.all(
                                  color: AppColors.accentVioletLight.withValues(
                                    alpha: borderAlpha,
                                  ),
                                  width: 1.5,
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    palette[0].withValues(alpha: 0.95),
                                    AppColors.surfaceElevated,
                                    palette[1].withValues(alpha: 0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                          // Idle light sweep (pre-play only)
                          if (!playing)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _ShimmerSweepPainter(
                                    progress: idleT,
                                    color: Colors.white.withValues(alpha: 0.07),
                                  ),
                                ),
                              ),
                            ),
                          // Soft sparkles when idle
                          if (!playing)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _SparklePainter(
                                    progress: _orbitController.value,
                                    color: AppColors.accentVioletLight
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ),
                          child!,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _FeaturedArtwork(
                  trackPaletteIndex: track.paletteIndex,
                  imageUrl: track.artworkUri,
                  orbit: _orbitController,
                  idle: _idleController,
                  playing: playing,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _FeaturedBadge(pulse: _idleController),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              'Local Song',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        track.title,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artist,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _FeaturedEqualizer(
                        playing: playing,
                        idle: _idleController,
                        active: _pulseController,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          _PlayPauseButton(
                            isPlaying: playing,
                            accent: palette[0],
                            idleHint: _idleController,
                            onPressed: _onPlayPause,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Lyrics',
                            onPressed: () => _openLyrics(context),
                            icon: const Icon(
                              Icons.lyrics_outlined,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeaturedEqualizer extends StatelessWidget {
  const _FeaturedEqualizer({
    required this.playing,
    required this.idle,
    required this.active,
  });

  final bool playing;
  final Animation<double> idle;
  final Animation<double> active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: Listenable.merge([idle, active]),
        builder: (context, _) {
          final t = playing ? active.value : idle.value;
          final heights = playing
              ? [
                  0.35 + t * 0.65,
                  0.55 + (1 - t) * 0.45,
                  0.4 + t * 0.5,
                  0.5 + (1 - t) * 0.4,
                  0.3 + t * 0.55,
                ]
              : [
                  0.25 + t * 0.2,
                  0.35 + (1 - t) * 0.15,
                  0.28 + t * 0.18,
                  0.32 + (1 - t) * 0.12,
                  0.22 + t * 0.16,
                ];
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < heights.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: 3.5,
                  height: 14 * heights[i],
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: playing
                        ? AppColors.accentVioletLight.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.35 + t * 0.25),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                playing ? 'Now playing' : 'Ready to play',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: playing ? 0.85 : 0.55),
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedArtwork extends StatelessWidget {
  const _FeaturedArtwork({
    required this.trackPaletteIndex,
    required this.imageUrl,
    required this.orbit,
    required this.idle,
    required this.playing,
  });

  final int trackPaletteIndex;
  final String? imageUrl;
  final AnimationController orbit;
  final AnimationController idle;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    const size = 108.0;
    return SizedBox(
      width: size + 18,
      height: size + 18,
      child: AnimatedBuilder(
        animation: Listenable.merge([orbit, idle]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer orbit ring (pre-play decoration)
              Transform.rotate(
                angle: orbit.value * math.pi * 2,
                child: CustomPaint(
                  size: const Size(size + 18, size + 18),
                  painter: _OrbitRingPainter(
                    color: AppColors.accentVioletLight.withValues(
                      alpha: playing ? 0.35 : 0.55 + idle.value * 0.25,
                    ),
                    strokeWidth: playing ? 1.2 : 1.6,
                    dashBoost: playing ? 0.4 : 1.0,
                  ),
                ),
              ),
              // Counter-rotating soft halo
              Transform.rotate(
                angle: -orbit.value * math.pi * 2 * 0.65,
                child: Container(
                  width: size + 8,
                  height: size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentViolet.withValues(
                        alpha: playing ? 0.15 : 0.22 + idle.value * 0.18,
                      ),
                      width: 1,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: playing ? 1.0 : 1.0 + idle.value * 0.02,
                child: child,
              ),
            ],
          );
        },
        child: MeloraArtwork(
          paletteIndex: trackPaletteIndex,
          size: size,
          borderRadius: AppSpacing.radiusMd,
          imageUrl: imageUrl,
        ),
      ),
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accentViolet.withValues(
              alpha: 0.32 + pulse.value * 0.18,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentVioletLight.withValues(
                  alpha: 0.15 + pulse.value * 0.2,
                ),
                blurRadius: 8 + pulse.value * 6,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Text(
        FeaturedSong.featuredLabel,
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.white,
          fontSize: 10,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.accent,
    required this.idleHint,
    required this.onPressed,
  });

  final bool isPlaying;
  final Color accent;
  final Animation<double> idleHint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: idleHint,
      builder: (context, child) {
        final hint = isPlaying ? 0.0 : idleHint.value;
        return Transform.scale(
          scale: 1.0 + hint * 0.03,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: [
                if (!isPlaying)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.18 + hint * 0.22),
                    blurRadius: 10 + hint * 8,
                    spreadRadius: hint * 1.5,
                  ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(isPlaying),
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isPlaying ? 'Pause' : 'Play',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashBoost,
  });

  final Color color;
  final double strokeWidth;
  final double dashBoost;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 1;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const segments = 14;
    final sweep = (math.pi * 2 / segments) * 0.55 * dashBoost;
    final gap = (math.pi * 2 / segments) - sweep;
    var start = -math.pi / 2;
    for (var i = 0; i < segments; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashBoost != dashBoost;
  }
}

class _ShimmerSweepPainter extends CustomPainter {
  _ShimmerSweepPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.4 + (size.width * 1.8 * progress);
    final rect = Rect.fromLTWH(x, 0, size.width * 0.35, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.transparent, color, Colors.transparent],
      ).createShader(rect);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerSweepPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final points = <Offset>[
      Offset(size.width * 0.88, size.height * 0.18),
      Offset(size.width * 0.78, size.height * 0.72),
      Offset(size.width * 0.22, size.height * 0.14),
      Offset(size.width * 0.12, size.height * 0.62),
    ];
    for (var i = 0; i < points.length; i++) {
      final phase = (progress + i * 0.21) % 1.0;
      final opacity = (0.15 + 0.55 * math.sin(phase * math.pi)).clamp(0.0, 1.0);
      final r = 1.2 + 1.6 * math.sin(phase * math.pi);
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(points[i], r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
