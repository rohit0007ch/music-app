/// A single lyric line, optionally timed for sync highlighting.
class LyricLine {
  const LyricLine({required this.text, this.start});

  final String text;

  /// Start offset from track beginning when timed lyrics are available.
  final Duration? start;

  bool get isTimed => start != null;
}

/// Lyrics payload for one track match from a provider.
class LyricsResult {
  const LyricsResult({
    required this.trackId,
    required this.sourceName,
    required this.lines,
    this.isInstrumental = false,
    this.providerTrackName,
    this.providerArtistName,
  });

  /// Melora [Track.id] this result was fetched for.
  final String trackId;

  /// Human-readable provider label (e.g. "LRCLIB").
  final String sourceName;

  final List<LyricLine> lines;
  final bool isInstrumental;
  final String? providerTrackName;
  final String? providerArtistName;

  bool get hasTimedLines => lines.any((l) => l.isTimed);
  bool get isEmpty => lines.isEmpty && !isInstrumental;

  /// Index of the active timed line for [position], or `-1` if not timed.
  int activeLineIndex(Duration position) {
    if (!hasTimedLines) return -1;
    var active = -1;
    for (var i = 0; i < lines.length; i++) {
      final start = lines[i].start;
      if (start == null) continue;
      if (start <= position) {
        active = i;
      } else {
        break;
      }
    }
    return active;
  }
}

/// Thrown when lyrics cannot be fetched due to network/provider failure.
class LyricsProviderException implements Exception {
  const LyricsProviderException(this.message);
  final String message;

  @override
  String toString() => message;
}
