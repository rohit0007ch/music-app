/// A music album.
class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    required this.trackCount,
    required this.paletteIndex,
  });

  final String id;
  final String title;
  final String artist;
  final int year;
  final int trackCount;
  final int paletteIndex;
}
