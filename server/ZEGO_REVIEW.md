# ZEGOCLOUD review integration

This branch is a review implementation, not a deployed or device-verified release.

## Implemented

- Flutter room cards retain their existing design and IDs `r1`–`r6`; server-created rooms are appended.
- Android/iOS use Live Audio Room Kit 3.16.12 for seats, text chat, signaling and audio effects. Flutter Web remains buildable and explicitly reports the native-kit limitation.
- Both token POST paths authenticate through Supabase, derive identity and role on the server, validate the room, and issue 15-minute Token04 credentials for AppID `828861219`. The unauthenticated GET token path is disabled.
- Seat leases prevent duplicate reservations and expire after 60 seconds without renewal. Client renewal runs every 20 seconds; seat changes refresh publishing privileges.
- Central Admin exposes room-scoped microphone permission and entry restrictions, with existing authorization and audit checks. The ordinary client applies these changes on renewal.
- Rose and crown gifts debit COINS and credit DIAMONDS through the existing ledger; prices are server-owned, replay keys are sender-scoped, and the ledger plus replay results are persisted together in SQLite. Effects are shown only after successful transactions. Clients poll committed gift events every three seconds.
- Existing update dialogs now check periodically as well as on startup/resume; download links require HTTPS and an approved store/repository host. Remote theme/feature controllers now notify the running UI.

## Configuration required before a trial

Use the actual Halla Render service; do not alter unrelated services. In its Environment page, set `ZEGO_APP_ID` to `828861219` and enter the project's 32-byte `ZEGO_SERVER_SECRET` directly in Render. Never paste it in chat, source, screenshots or client build settings. Use **Save only** while publication remains unapproved. Existing Supabase server variables must match the Flutter account project.

The connected Render workspace currently exposes only `matjar2023`, not Halla. A read-only request to `https://halla.onrender.com/health` returned HTTP 404 on 2026-11-26. The branch adds `/health` and `/healthz`; their local tests pass, but those routes have not been deployed.

The SQLite database must live on an existing persistent volume before using real funds. This branch does not provision a disk or any paid resource. The current ledger is suitable for a single-process trial, not a multi-instance financial service. Existing local HTML/browser balances are untrusted and are deliberately not imported as spendable server funds.

## Review checks

- Run `node --test app.test.mjs src/central-admin.test.mjs src/gifts.test.mjs` from `server/`.
- Run `flutter pub get`, `flutter analyze --no-fatal-infos --no-fatal-warnings`, and `flutter build web --release` in both Flutter apps. Existing lint/deprecation warnings remain visible.
- The review workflow compiles debug Android artifacts and unsigned iOS without publishing a Release or deploying web output. It requires no deployment secrets.
- Local native Android build is blocked by missing Android SDK; iOS requires macOS/Xcode. A successful web build does not prove native voice works.

## Remaining acceptance work

1. Confirm trial quota and ZEGO audio/ZIM activation in the correct project; no paid plan is enabled by this branch.
2. Configure Server Secret on the correct trial server and explicitly authorize a trial deployment.
3. On two physical phones, test joining every original/custom room, headset permission, seat contention, host invitations, chat, reconnection, token expiry, admin changes and duplicate gift requests.
4. Provider-enforced immediate kick/mute for a modified client needs ZEGO server APIs and credential-expiry enforcement. The present admin controls are checked by the server on new tokens and applied by the normal client within 20 seconds; they are not a claim of immediate provider-level eviction.
5. Gift effects currently use animated emoji plus a system click; premium video/Lottie/sound assets and VIP-specific gift eligibility are not implemented. No existing VIP tier is converted into an administrative role.
6. Background push notifications require FCM/APNs setup and device registration. This branch supplies in-app update notices, not push delivery to closed apps.
7. Keep `app_version.json` unchanged until a signed, compatible installable artifact is tested and published with authorization. APK updates require the same application ID and signing certificate as installed versions; iPhone updates require an approved distribution path. No silent native binary installation is attempted.

The legacy standalone `zego-room.html` is not used by the Flutter integration and is not a supported acceptance target for this branch.
