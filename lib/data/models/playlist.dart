import 'package:melora_music/data/models/track.dart';

/// A user playlist.
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.tracks,
    required this.paletteIndex,
  });

  final String id;
  final String name;
  final List<Track> tracks;
  final int paletteIndex;

  int get trackCount => tracks.length;
}
