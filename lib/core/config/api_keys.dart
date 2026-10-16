/// Centralized API keys and app identifiers for Google Maps / Geocoding.
///
/// For production, prefer using [String.fromEnvironment] or dart-define:
/// `String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: _defaultKey)`
const String googleMapsApiKey =
    String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: 'AIzaSyCMBZXflL1KxJTfRbzmznV9vFE4xJfaQOY');

/// iOS bundle identifier. Used in [geoCodingApiHeaders] when the API key is restricted by app.
const String iosBundleId = 'com.techlapse.foodApp';

/// Android application ID. Used in [geoCodingApiHeaders] when the API key is restricted by app.
const String androidPackageName = 'com.example.food_app';

/// Android signing certificate SHA-1. Required when the API key is restricted to Android apps.
/// Set via --dart-define=ANDROID_SHA1=your_sha1 when building.
const String androidSha1Cert =
    String.fromEnvironment('ANDROID_SHA1', defaultValue: '');
