/// Jamendo API configuration.
///
/// A default Client ID is baked in so `flutter run` works on any device with
/// no extra flags. Override at build time if needed:
/// ```
/// flutter run --dart-define=JAMENDO_CLIENT_ID=other_id
/// ```
///
/// Never put a client secret in the app. OAuth write APIs are out of scope for
/// Milestone 3; read/stream calls only need [clientId].
abstract final class JamendoConfig {
  /// Read-only API client id (override with `--dart-define=JAMENDO_CLIENT_ID=`).
  static const String clientId = String.fromEnvironment(
    'JAMENDO_CLIENT_ID',
    defaultValue: 'e54e7628',
  );

  static bool get isConfigured => clientId.trim().isNotEmpty;

  /// Base URL for Jamendo API v3.0 (HTTPS).
  static const String apiBaseUrl = 'https://api.jamendo.com/v3.0';
}
