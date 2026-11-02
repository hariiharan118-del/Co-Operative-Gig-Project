# KRIYANTA Partner

Worker-facing Flutter app for the same cooperative household-services marketplace as the customer app.

## Stack

- **State:** `flutter_riverpod`
- **Navigation:** `go_router` with auth + verification redirects
- **HTTP:** `dio` (`ApiClient` attaches JWT, refreshes on 401)
- **Tokens:** `flutter_secure_storage`
- **Realtime:** `socket_io_client` (`SocketService` singleton)
- **Push:** `firebase_core` + `firebase_messaging` (permission on launch, token printed)
- **Maps:** `flutter_map` + OpenStreetMap tiles (active-job tracking)
- **Deep links:** `url_launcher` (`google.navigation:q=lat,lng`)
- **i18n:** `easy_localization` (English now; add locales later)

`ApiClient` and `SocketService` match the customer app so auth, refresh, and socket wiring can be ported later.

## Run

```bash
flutter pub get
cp .env.example .env   # then set API_BASE_URL
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

`--dart-define=API_BASE_URL=...` wins over `.env`. Use **Continue with demo data** on the login screen to explore the rest of the app without a backend.

## Auth API (live)

| Method | Path | Body |
| --- | --- | --- |
| POST | `/auth/otp/request` | `{ "phone": "+91..." }` |
| POST | `/auth/otp/verify` | `{ "phone": "+91...", "otp": "123456" }` |

Verify should return `{ "accessToken", "refreshToken", "user"? }`. Refresh uses `POST /auth/refresh`.

After login the router checks verification. That check is **mocked as approved** so the dashboard is reachable. Search `GET /workers/verification-status` for the plug-in point.

Everything else uses in-memory mock data. Search the repo for `TODO:` to find the endpoint each screen should call.

## Screens

| Screen | Route | Notes |
| --- | --- | --- |
| Phone + OTP | `/login`, `/otp` | Real auth endpoints |
| Verification gate | `/verification` | Blocks pending/rejected workers |
| Dashboard | `/dashboard` | Online toggle + nearby job feed |
| Active job | `/job/:id` | Map, ETA pill, status-driven CTA |
| Earnings | `/earnings` | Wallet + payout request |
| History | `/history` | Completed jobs |
| Support | `/support` | Same chat pattern as the customer app |
| Profile | `/profile` | Edit + certifications |
| Welfare | `/profile/welfare` | Enrollment + claims |

The active-job primary button reads `JobLifecycleStatus.primaryAction` (Navigate → I've arrived → Start job → Complete job). Do not add per-screen status `if`s for that button.

## Maps

Active-job tracking uses `flutter_map` with OpenStreetMap's public tile server. The tile layer sends a User-Agent (`com.coopgig.coop_gig_worker`) as required by OSM's usage policy. Navigate still opens the device maps app via `url_launcher`.

## Firebase

Add `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` (FlutterFire CLI). Until then, FCM init is skipped so the rest of the app still runs.

## Add a language

1. Copy `assets/translations/en.json` to `assets/translations/<code>.json`.
2. Add `Locale('<code>')` to `supportedLocales` in `lib/main.dart`.
