import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/models/album.dart';
import 'package:melora_music/data/models/artist.dart';
import 'package:melora_music/data/models/playlist.dart';

/// All mock data for the Melora UI prototype.
abstract final class MockData {
  static final List<Track> tracks = [
    const Track(
      id: 't1',
      title: 'Neon Dreams',
      artist: 'Aether Pulse',
      album: 'Luminance',
      durationSeconds: 214,
      paletteIndex: 0,
      isFavourite: true,
      genre: 'Electronic',
    ),
    const Track(
      id: 't2',
      title: 'Midnight Cascade',
      artist: 'Vera Sol',
      album: 'Stellarwave',
      durationSeconds: 187,
      paletteIndex: 1,
      genre: 'Indie',
    ),
    const Track(
      id: 't3',
      title: 'Crystal Orbit',
      artist: 'Aether Pulse',
      album: 'Luminance',
      durationSeconds: 243,
      paletteIndex: 0,
      isFavourite: true,
      genre: 'Electronic',
    ),
    const Track(
      id: 't4',
      title: 'Ember Skies',
      artist: 'Rio Vex',
      album: 'Terraformed',
      durationSeconds: 198,
      paletteIndex: 3,
      genre: 'Ambient',
    ),
    const Track(
      id: 't5',
      title: 'Forest Protocol',
      artist: 'Lumis',
      album: 'Green Signal',
      durationSeconds: 227,
      paletteIndex: 4,
      genre: 'Lofi',
    ),
    const Track(
      id: 't6',
      title: 'Violet Hour',
      artist: 'Vera Sol',
      album: 'Stellarwave',
      durationSeconds: 205,
      paletteIndex: 5,
      isFavourite: true,
      genre: 'Pop',
    ),
    const Track(
      id: 't7',
      title: 'Static Rain',
      artist: 'Nox Circuit',
      album: 'Voltage',
      durationSeconds: 176,
      paletteIndex: 6,
      genre: 'Electronic',
    ),
    const Track(
      id: 't8',
      title: 'Solar Drift',
      artist: 'Rio Vex',
      album: 'Terraformed',
      durationSeconds: 262,
      paletteIndex: 7,
      genre: 'Ambient',
    ),
    const Track(
      id: 't9',
      title: 'Indigo Pulse',
      artist: 'Nox Circuit',
      album: 'Voltage',
      durationSeconds: 193,
      paletteIndex: 2,
      isFavourite: true,
      genre: 'Electronic',
    ),
    const Track(
      id: 't10',
      title: 'Morning Protocol',
      artist: 'Lumis',
      album: 'Green Signal',
      durationSeconds: 218,
      paletteIndex: 4,
      isDownloaded: true,
      genre: 'Lofi',
    ),
    const Track(
      id: 't11',
      title: 'Phantom Signal',
      artist: 'Aether Pulse',
      album: 'Luminance',
      durationSeconds: 231,
      paletteIndex: 0,
      isDownloaded: true,
      genre: 'Electronic',
    ),
    const Track(
      id: 't12',
      title: 'Tidal Wave',
      artist: 'Vera Sol',
      album: 'Stellarwave',
      durationSeconds: 199,
      paletteIndex: 1,
      isDownloaded: true,
      genre: 'Indie',
    ),
  ];

  static List<Track> get favourites =>
      tracks.where((t) => t.isFavourite).toList();

  static List<Track> get downloaded =>
      tracks.where((t) => t.isDownloaded).toList();

  static final List<Album> albums = [
    const Album(
      id: 'a1',
      title: 'Luminance',
      artist: 'Aether Pulse',
      year: 2025,
      trackCount: 3,
      paletteIndex: 0,
    ),
    const Album(
      id: 'a2',
      title: 'Stellarwave',
      artist: 'Vera Sol',
      year: 2024,
      trackCount: 3,
      paletteIndex: 1,
    ),
    const Album(
      id: 'a3',
      title: 'Terraformed',
      artist: 'Rio Vex',
      year: 2025,
      trackCount: 2,
      paletteIndex: 3,
    ),
    const Album(
      id: 'a4',
      title: 'Green Signal',
      artist: 'Lumis',
      year: 2023,
      trackCount: 2,
      paletteIndex: 4,
    ),
    const Album(
      id: 'a5',
      title: 'Voltage',
      artist: 'Nox Circuit',
      year: 2026,
      trackCount: 2,
      paletteIndex: 6,
    ),
  ];

  static final List<Artist> artists = [
    const Artist(
      id: 'ar1',
      name: 'Aether Pulse',
      trackCount: 3,
      paletteIndex: 0,
    ),
    const Artist(id: 'ar2', name: 'Vera Sol', trackCount: 3, paletteIndex: 1),
    const Artist(id: 'ar3', name: 'Rio Vex', trackCount: 2, paletteIndex: 3),
    const Artist(id: 'ar4', name: 'Lumis', trackCount: 2, paletteIndex: 4),
    const Artist(
      id: 'ar5',
      name: 'Nox Circuit',
      trackCount: 2,
      paletteIndex: 6,
    ),
  ];

  static final List<Playlist> playlists = [
    Playlist(
      id: 'p1',
      name: 'Late Night Vibes',
      tracks: [tracks[0], tracks[5], tracks[8]],
      paletteIndex: 5,
    ),
    Playlist(
      id: 'p2',
      name: 'Focus Mode',
      tracks: [tracks[4], tracks[9], tracks[3]],
      paletteIndex: 4,
    ),
    Playlist(
      id: 'p3',
      name: 'Workout Boost',
      tracks: [tracks[6], tracks[1], tracks[7]],
      paletteIndex: 7,
    ),
    Playlist(
      id: 'p4',
      name: 'Chill Sundays',
      tracks: [tracks[2], tracks[5], tracks[4], tracks[11]],
      paletteIndex: 2,
    ),
  ];

  static const List<String> genres = [
    'All',
    'Electronic',
    'Indie',
    'Ambient',
    'Lofi',
    'Pop',
    'Hip-Hop',
    'Jazz',
    'Classical',
    'R&B',
  ];

  static const List<Map<String, dynamic>> moods = [
    {'label': 'Energetic', 'icon': '⚡', 'paletteIndex': 3},
    {'label': 'Chill', 'icon': '🌊', 'paletteIndex': 2},
    {'label': 'Focus', 'icon': '🎯', 'paletteIndex': 4},
    {'label': 'Happy', 'icon': '✨', 'paletteIndex': 0},
    {'label': 'Melancholy', 'icon': '🌙', 'paletteIndex': 5},
    {'label': 'Romantic', 'icon': '💜', 'paletteIndex': 1},
  ];

  static const List<String> mockLyrics = [
    'Falling through the neon light',
    'A cascade of violet night',
    'I chase the signal, I chase the sound',
    "A frequency that can't be found",
    '',
    'In the dream, in the dream',
    'Everything is what it seems',
    'Till the morning breaks the seam',
    "And we're lost inside the stream",
    '',
    'Crystal orbit, pull me in',
    'Where the circuits always win',
    'Static waves upon the shore',
    'I keep asking for some more',
    '',
    'In the dream, in the dream',
    'Everything is what it seems',
    'Till the morning breaks the seam',
    "And we're lost inside the stream",
  ];
}
