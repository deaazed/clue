# Google Sign-In setup (one-time, ~10 minutes)

The app's email+password sign-in works out of the box. The **Continue with
Google** button stays hidden until you complete these steps.

## 1. Create the OAuth clients in Google Cloud Console

1. Go to <https://console.cloud.google.com/> → create (or pick) a project, e.g. `clue`.
2. **APIs & Services → OAuth consent screen**: External, app name `Clue`, add your email, save. Test mode is fine.
3. **APIs & Services → Credentials → Create credentials → OAuth client ID**, twice:

   **a) Android client** (lets the device sign in)
   - Application type: **Android**
   - Package name: `com.clue.clue_sl` (check `android/app/build.gradle` → `applicationId`)
   - SHA-1: run
     ```
     cd apps/mobile.v0/android && ./gradlew signingReport
     ```
     and copy the SHA-1 of the `debug` variant (add your release SHA-1 later too).

   **b) Web application client** (lets the *backend* verify tokens)
   - Application type: **Web application**, name e.g. `clue-backend`
   - No redirect URIs needed.
   - Copy its **Client ID** — this is the value used below.

## 2. Wire the Web client ID into the app

In [apps/mobile.v0/lib/config.dart](../apps/mobile.v0/lib/config.dart):

```dart
const String kGoogleServerClientId = '<WEB_CLIENT_ID>.apps.googleusercontent.com';
```

That makes the Google button appear on the Account page and gives the app an
ID token the backend can verify.

## 3. (Recommended) Pin the client ID on the server

On the VPS, add to the backend environment (docker-compose or `.env`):

```
GOOGLE_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com
```

Without it the backend still verifies tokens cryptographically via Google's
tokeninfo endpoint, but with it, tokens minted for *other* apps are rejected
too.

## How it works

```
device --Google Sign-In--> Google  (returns ID token)
device --POST /api/auth/google {id_token}--> backend
backend --GET tokeninfo--> Google  (validates signature, expiry, audience)
backend: upsert user 'google:<sub>', mint bearer token (UUID)
device: stores token; all uploads send Authorization: Bearer <token>
```
