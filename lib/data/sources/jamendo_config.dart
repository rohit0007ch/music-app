/// Jamendo API configuration injected at build/run time.
///
/// Pass the client ID without committing it:
/// ```
/// flutter run --dart-define=JAMENDO_CLIENT_ID=your_client_id
/// flutter test --dart-define=JAMENDO_CLIENT_ID=test
/// ```
///
/// Never put [clientSecret] in the app. OAuth write APIs are out of scope for
/// Milestone 3; read/stream calls only need [clientId].
abstract final class JamendoConfig {
  /// Read-only API client id from `--dart-define=JAMENDO_CLIENT_ID=...`.
  static const String clientId = String.fromEnvironment('JAMENDO_CLIENT_ID');

  static bool get isConfigured => clientId.trim().isNotEmpty;

  /// Base URL for Jamendo API v3.0 (HTTPS).
  static const String apiBaseUrl = 'https://api.jamendo.com/v3.0';
}
