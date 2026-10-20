/// A music artist.
class Artist {
  const Artist({
    required this.id,
    required this.name,
    required this.trackCount,
    required this.paletteIndex,
  });

  final String id;
  final String name;
  final int trackCount;
  final int paletteIndex;
}
