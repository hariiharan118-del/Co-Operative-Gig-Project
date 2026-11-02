# CoopGig Customer

Customer-facing Flutter app for a cooperative household-services marketplace (electrician, plumber, carpenter, and similar gigs).

## Stack

- **State:** `flutter_riverpod`
- **Navigation:** `go_router` with an auth redirect
- **HTTP:** `dio` (`ApiClient` attaches JWT, refreshes on 401)
- **Tokens:** `flutter_secure_storage`
- **Realtime:** `socket_io_client` (`SocketService` singleton)
- **Push:** `firebase_core` + `firebase_messaging` (permission on launch, token printed)
- **Maps:** `google_maps_flutter` (tracking screen; live updates left as TODO)
- **i18n:** `easy_localization` (English now; add locales later)

## Run

```bash
flutter pub get
cp .env.example .env   # then set API_BASE_URL
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

`--dart-define=API_BASE_URL=...` wins over `.env`.

## Auth API (live)

| Method | Path | Body |
| --- | --- | --- |
| POST | `/auth/otp/request` | `{ "phone": "+91..." }` |
| POST | `/auth/otp/verify` | `{ "phone": "+91...", "otp": "123456" }` |

Verify should return `{ "accessToken", "refreshToken", "user"? }`. Refresh uses `POST /auth/refresh`.

Everything else uses in-memory mock data. Search the repo for `TODO:` to find the endpoint each screen should call.

## Google Maps

1. Enable Maps SDK for Android and iOS in Google Cloud.
2. Put the key in Android `AndroidManifest.xml` (`com.google.android.geo.API_KEY`) and in iOS `AppDelegate.swift` (`GMSServices.provideAPIKey`).
3. You can also set `GOOGLE_MAPS_API_KEY` in `.env` for documentation; native keys still have to be in the platform files.

## Firebase

Add `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` (FlutterFire CLI). Until then, FCM init is skipped so the rest of the app still runs.

## Add a language

1. Copy `assets/translations/en.json` to `assets/translations/<code>.json`.
2. Add `Locale('<code>')` to `supportedLocales` in `lib/main.dart`.
