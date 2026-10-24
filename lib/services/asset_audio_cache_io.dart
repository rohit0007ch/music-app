import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Copies a Flutter asset into a temp file and returns a `file://` [AudioSource].
///
/// Used on VM / mobile / desktop. Web uses [asset_audio_cache_web.dart] instead.
Future<AudioSource> cachedAssetAudioSource({
  required String trackId,
  required String assetPath,
  required MediaItem tag,
  AssetBundle? bundle,
  Directory? cacheDirectory,
}) async {
  final file = await materializeAssetFile(
    trackId: trackId,
    assetPath: assetPath,
    bundle: bundle,
    cacheDirectory: cacheDirectory,
  );
  return AudioSource.uri(Uri.file(file.path), tag: tag);
}

/// Copies a Flutter asset into a stable temp file for native playback.
Future<File> materializeAssetFile({
  required String trackId,
  required String assetPath,
  AssetBundle? bundle,
  Directory? cacheDirectory,
}) async {
  final safeId = trackId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final ext = assetPath.contains('.')
      ? assetPath.substring(assetPath.lastIndexOf('.') + 1)
      : 'mp3';
  final dir =
      cacheDirectory ??
      Directory('${Directory.systemTemp.path}/melora_bundled_audio');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final out = File('${dir.path}/$safeId.$ext');
  if (await out.exists() && await out.length() > 0) {
    return out;
  }

  final data = await (bundle ?? rootBundle).load(assetPath);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  if (bytes.isEmpty) {
    throw StateError('Bundled asset "$assetPath" is empty.');
  }
  await out.writeAsBytes(bytes, flush: true);
  return out;
}
