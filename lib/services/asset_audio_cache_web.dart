import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Web: play directly from the Flutter asset bundle (no `dart:io` files).
Future<AudioSource> cachedAssetAudioSource({
  required String trackId,
  required String assetPath,
  required MediaItem tag,
  Object? bundle,
  Object? cacheDirectory,
}) async {
  assert(trackId.isNotEmpty);
  assert(bundle == null);
  assert(cacheDirectory == null);
  return AudioSource.asset(assetPath, tag: tag);
}
