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

    return items.compactMap { item -> [String: Any]? in
      guard let assetURL = item.assetURL else { return nil }
      let id = item.persistentID
      return [
        "id": Int(id & 0x7fffffffffffffff),
        "title": item.title ?? "Unknown title",
        "artist": item.artist ?? "Unknown artist",
        "album": item.albumTitle ?? "Unknown album",
        "durationMs": Int((item.playbackDuration * 1000.0).rounded()),
        "uri": assetURL.absoluteString,
        "genre": item.genre ?? "",
      ]
    }
  }
}
