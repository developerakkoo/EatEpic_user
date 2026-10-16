/// Google Sign-In configuration.
///
/// The Web client ID must match `GOOGLE_WEB_CLIENT_ID` on Lunch-Box-API.
/// Pass it at build/run time (preferred) so the same value is not hardcoded:
///
/// ```
/// flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
/// ```
///
/// Google Cloud Console:
/// 1. OAuth consent screen
/// 2. Web client ID  -> dart-define + API env (token audience)
/// 3. Android client -> package `com.eatepic.user` + SHA-1
/// 4. iOS client     -> bundle `com.eatepic.user` + Info.plist GIDClientID
class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// OAuth 2.0 Web client ID. Used as `serverClientId` so Google returns an
  /// ID token the API can verify.
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: _embeddedWebClientId,
  );

  /// iOS OAuth client ID (optional). Info.plist GIDClientID is used if empty.
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: _embeddedIosClientId,
  );

  // MUST be a *Web application* OAuth client ID (client_type 3).
  // An Android client ID here causes: "developer console is not set up correctly".
  // Override with --dart-define=GOOGLE_WEB_CLIENT_ID=...
  static const String _embeddedWebClientId =
      '484453819210-5keha473v278u2ehb0a6j5bs7l6qdg8b.apps.googleusercontent.com';

  // Paste the iOS client ID here if you are not using --dart-define / Info.plist.
  static const String _embeddedIosClientId = '';

  static bool get isConfigured {
    final id = serverClientId.trim();
    return id.isNotEmpty &&
        id.contains('.apps.googleusercontent.com') &&
        !id.startsWith('REPLACE_');
  }
}
