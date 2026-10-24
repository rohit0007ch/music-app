import 'package:flutter/services.dart';
import 'package:melora_music/data/models/lyrics.dart';
import 'package:melora_music/data/models/track.dart';

/// Bundled featured track — Dinesh Dalla.
///
/// Stable id must not collide with Jamendo (`online_*`) or device-library
/// (`local_*`) ids. Audio and lyrics ship as Flutter assets.
abstract final class FeaturedSong {
  static const String id = 'featured_dinesh_dalla';
  static const String title = 'Dinesh Dalla';
  static const String artist = 'Dinesh';
  static const String album = 'Featured';
  static const String featuredLabel = 'FEATURED SONG';
  static const String audioAssetPath = 'assets/audio/dinesh.mp3';
  static const String lyricsAssetPath = 'assets/lyrics/dinesh_dalla.txt';

  /// Drop the supplied thumbnail at one of these paths, then set
  /// [artworkAssetPath] to that path so MeloraArtwork loads it.
  /// Leave `null` until the image is in the project (gradient fallback).
  static const String? artworkAssetPath = null;

  /// Preferred drop locations (document for the user; not auto-scanned).
  static const String preferredArtworkJpg =
      'assets/images/featured/dinesh_dalla.jpg';
  static const String preferredArtworkPng =
      'assets/images/featured/dinesh_dalla.png';

  /// Estimated duration from the bundled MP3 (~171.5 s).
  static const int durationSeconds = 172;

  static const int paletteIndex = 0;

  /// Canonical [Track] for the shared player / queue.
  static Track get track => Track(
    id: id,
    title: title,
    artist: artist,
    album: album,
    durationSeconds: durationSeconds,
    paletteIndex: paletteIndex,
    source: TrackSource.asset,
    assetPath: audioAssetPath,
    artworkUri: artworkAssetPath,
    genre: 'Featured',
  );

  static bool isFeaturedId(String? trackId) => trackId == id;

  /// Loads bundled plain-text lyrics. Never hits a network API.
  static Future<LyricsResult> loadLyrics() async {
    final raw = await rootBundle.loadString(lyricsAssetPath);
    return LyricsResult(
      trackId: id,
      sourceName: 'Bundled',
      lines: parseBundledLyrics(raw),
    );
  }

  /// Preserves blank lines, section labels, punctuation, and emojis.
  static List<LyricLine> parseBundledLyrics(String plain) {
    final normalized = plain.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Drop a single trailing newline so the last visual line isn't empty,
    // but keep intentional blank lines between sections.
    final trimmedEnd = normalized.endsWith('\n')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    return [for (final line in trimmedEnd.split('\n')) LyricLine(text: line)];
  }
}
