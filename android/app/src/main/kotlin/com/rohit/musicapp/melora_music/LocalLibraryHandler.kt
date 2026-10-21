package com.rohit.musicapp.melora_music

import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// Queries [MediaStore.Audio.Media] and returns maps for Dart [Track] mapping.
class LocalLibraryHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "querySongs" -> {
                try {
                    result.success(querySongs())
                } catch (e: Exception) {
                    result.error("QUERY_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun querySongs(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.ALBUM_ID,
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC}!=0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
        val artworkByAlbum = mutableMapOf<Long, String?>()

        context.contentResolver.query(
            collection,
            projection,
            selection,
            null,
            sortOrder,
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val albumId = cursor.getLong(albumIdCol)
                val contentUri = ContentUris.withAppendedId(collection, id)
                val artworkUri = if (albumId > 0L) {
                    artworkByAlbum.getOrPut(albumId) { resolveAlbumArtwork(albumId) }
                } else {
                    null
                }
                songs.add(
                    mapOf(
                        "id" to id,
                        "title" to cursor.getString(titleCol),
                        "artist" to cursor.getString(artistCol),
                        "album" to cursor.getString(albumCol),
                        "durationMs" to cursor.getLong(durationCol),
                        "uri" to contentUri.toString(),
                        "genre" to "",
                        "artworkUri" to artworkUri,
                    ),
                )
            }
        }
        return songs
    }

    /// Copies album art into the app cache as a file:// URI when available.
    /// Returns null when the album has no readable artwork.
    private fun resolveAlbumArtwork(albumId: Long): String? {
        val artContentUri = ContentUris.withAppendedId(
            Uri.parse("content://media/external/audio/albumart"),
            albumId,
        )
        val outFile = File(context.cacheDir, "melora_albumart_$albumId.jpg")
        return try {
            if (!outFile.exists() || outFile.length() == 0L) {
                context.contentResolver.openInputStream(artContentUri)?.use { input ->
                    outFile.outputStream().use { output -> input.copyTo(output) }
                } ?: return null
            }
            if (outFile.length() > 0L) outFile.toURI().toString() else null
        } catch (_: Exception) {
            // Missing or unreadable album art — leave artwork null for gradient fallback.
            null
        }
    }
}
