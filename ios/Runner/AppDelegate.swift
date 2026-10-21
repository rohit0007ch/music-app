import Flutter
import MediaPlayer
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerLocalLibraryChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  private func registerLocalLibraryChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "melora_music/local_library",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "querySongs":
        result(Self.querySongs())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func querySongs() -> [[String: Any]] {
    let query = MPMediaQuery.songs()
    guard let items = query.items else { return [] }

    var artworkByAlbum = [UInt64: String?]()

    return items.compactMap { item -> [String: Any]? in
      guard let assetURL = item.assetURL else { return nil }
      let id = item.persistentID
      let albumKey = item.albumPersistentID
      let artworkUri: String?
      if albumKey != 0 {
        if let cached = artworkByAlbum[albumKey] {
          artworkUri = cached
        } else {
          let resolved = Self.resolveArtworkFileURL(for: item, albumKey: albumKey)
          artworkByAlbum[albumKey] = resolved
          artworkUri = resolved
        }
      } else {
        artworkUri = Self.resolveArtworkFileURL(for: item, albumKey: id)
      }

      var map: [String: Any] = [
        "id": Int(id & 0x7fffffffffffffff),
        "title": item.title ?? "Unknown title",
        "artist": item.artist ?? "Unknown artist",
        "album": item.albumTitle ?? "Unknown album",
        "durationMs": Int((item.playbackDuration * 1000.0).rounded()),
        "uri": assetURL.absoluteString,
        "genre": item.genre ?? "",
      ]
      if let artworkUri {
        map["artworkUri"] = artworkUri
      }
      return map
    }
  }

  /// Writes a JPEG thumbnail into the caches directory when artwork exists.
  private static func resolveArtworkFileURL(for item: MPMediaItem, albumKey: UInt64) -> String? {
    guard let artwork = item.artwork,
          let image = artwork.image(at: CGSize(width: 300, height: 300)),
          let data = image.jpegData(compressionQuality: 0.82)
    else {
      return nil
    }

    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    guard let caches else { return nil }
    let fileURL = caches.appendingPathComponent("melora_albumart_\(albumKey).jpg")
    do {
      if !FileManager.default.fileExists(atPath: fileURL.path) {
        try data.write(to: fileURL, options: .atomic)
      }
      return fileURL.absoluteString
    } catch {
      return nil
    }
  }
}
