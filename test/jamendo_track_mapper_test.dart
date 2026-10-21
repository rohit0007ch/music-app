import 'package:flutter_test/flutter_test.dart';
import 'package:melora_music/data/models/track.dart';
import 'package:melora_music/data/sources/jamendo_track_mapper.dart';

void main() {
  group('JamendoTrackMapper', () {
    test('maps a valid streamable track with license attribution URL', () {
      final track = JamendoTrackMapper.fromJson({
        'id': 1848357,
        'name': 'Groove Track',
        'artist_name': 'Indie Artist',
        'album_name': 'Demo Album',
        'duration': 214,
        'audio':
            'https://prod-1.storage.jamendo.com/?trackid=1848357&format=mp32',
        'image': 'https://img.jamendo.com/cover.jpg',
        'license_ccurl': 'http://creativecommons.org/licenses/by-nc-nd/3.0/',
        'audiodownload': 'https://example.com/download/should-be-ignored',
        'audiodownload_allowed': true,
        'musicinfo': {
          'tags': {
            'genres': ['rock', 'pop'],
          },
        },
      });

      expect(track, isNotNull);
      expect(track!.id, 'online_1848357');
      expect(track.source, TrackSource.online);
      expect(track.title, 'Groove Track');
      expect(track.artist, 'Indie Artist');
      expect(track.album, 'Demo Album');
      expect(track.durationSeconds, 214);
      expect(track.streamUrl, contains('trackid=1848357'));
      expect(track.localUri, isNull);
      expect(track.playbackUri, track.streamUrl);
      expect(track.isPlayable, isTrue);
      expect(track.artworkUri, 'https://img.jamendo.com/cover.jpg');
      expect(
        track.licenseUrl,
        'http://creativecommons.org/licenses/by-nc-nd/3.0/',
      );
      expect(track.genre, 'rock');
      // Download fields must never become the playback URI.
      expect(track.streamUrl, isNot(contains('download')));
    });

    test('returns null when audio stream URL is missing', () {
      expect(
        JamendoTrackMapper.fromJson({
          'id': 1,
          'name': 'Silent',
          'artist_name': 'A',
          'album_name': 'B',
          'duration': 10,
          'audiodownload': 'https://example.com/dl',
          'audiodownload_allowed': true,
        }),
        isNull,
      );
    });

    test('returns null when audio stream URL is blank', () {
      expect(
        JamendoTrackMapper.fromJson({
          'id': 2,
          'name': 'Blank Audio',
          'audio': '   ',
        }),
        isNull,
      );
    });

    test('returns null for non-http(s) audio schemes', () {
      expect(
        JamendoTrackMapper.fromJson({
          'id': 3,
          'name': 'Odd',
          'audio': 'ftp://example.com/a.mp3',
        }),
        isNull,
      );
    });

    test('fills fallbacks when metadata fields are missing', () {
      final track = JamendoTrackMapper.fromJson({
        'id': '99',
        'audio': 'https://cdn.example.com/t.mp3',
      });

      expect(track, isNotNull);
      expect(track!.title, 'Unknown title');
      expect(track.artist, 'Unknown artist');
      expect(track.album, 'Unknown album');
      expect(track.durationSeconds, 0);
      expect(track.licenseUrl, isNull);
      expect(track.genre, isEmpty);
    });

    test('mapAll drops entries without usable audio', () {
      final tracks = JamendoTrackMapper.mapAll([
        {'id': 1, 'name': 'Keep', 'audio': 'https://cdn.example.com/a.mp3'},
        {'id': 2, 'name': 'Drop', 'audio': ''},
        {'id': 3, 'name': 'Keep2', 'audio': 'https://cdn.example.com/b.mp3'},
      ]);

      expect(tracks.map((t) => t.id), ['online_1', 'online_3']);
    });
  });
}
