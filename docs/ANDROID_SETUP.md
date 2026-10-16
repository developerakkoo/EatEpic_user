# Android setup

This document describes the Android configuration required for the Food App and its libraries.

## Permissions

The app declares the following in `android/app/src/main/AndroidManifest.xml`:

- **INTERNET** – Network access (API calls, images, Maps).
- **ACCESS_FINE_LOCATION** / **ACCESS_COARSE_LOCATION** – For location picker and delivery address.
- **POST_NOTIFICATIONS** – For order updates (Android 13+).

Location is optional at install time: `uses-feature android:name="android.hardware.location.gps" android:required="false"` so the app can be installed on devices without GPS.

## Google Maps / Geocoding (map_location_picker)

The app uses Google Maps for the location picker. The API key is set in the manifest as `com.google.android.geo.API_KEY`.

### Google Cloud Console

In [Google Cloud Console](https://console.cloud.google.com/) (project that owns the API key), enable:

1. **Maps SDK for Android** – Required for the map.
2. **Geocoding API** – Required for address search and reverse geocoding.

If the location picker uses Places search, also enable **Places API** (or the specific Places product used by the package).

### API key restriction (optional)

To restrict the key to this app:

1. In Cloud Console, open **APIs & Services** → **Credentials** → your API key.
2. Under **Application restrictions**, choose **Android apps**.
3. Add an entry:
   - **Package name:** `com.example.food_app` (must match `applicationId` in `android/app/build.gradle.kts`).
   - **SHA-1:** For debug builds use your debug keystore SHA-1; for release use your release signing key SHA-1.

The app can send the SHA-1 via request headers when calling Geocoding (see `lib/core/config/api_keys.dart`: `androidPackageName`, `androidSha1Cert`). Set `ANDROID_SHA1` via `--dart-define=ANDROID_SHA1=your_sha1` when building if you use header-based restriction.

## Build configuration

- **minSdk:** 21 (permission_handler, map_location_picker, and other plugins).
- **compileSdk:** 34.
- **AndroidX** and **Jetifier** are enabled in `android/gradle.properties`.

## Verification

1. Run `flutter clean && flutter pub get`.
2. Run `flutter run` (or build an APK) and go through: splash → onboarding → permissions → login → home.
3. Open the location picker (e.g. from home or cart) and confirm the map loads.
4. On Android 13+, confirm the notification permission is requested.

If the map does not load, verify in Cloud Console that **Maps SDK for Android** and **Geocoding API** are enabled for the project that owns the API key.
