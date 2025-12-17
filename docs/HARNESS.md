Headless Firebase Auth + Firestore validation (emulator)

This harness validates Firebase Authentication (email/password) and Firestore user document behavior using the Firebase Emulator Suite and simple REST calls. It avoids running the full Flutter app or device-level integration tests, making it fast and lightweight to run locally.

What it checks
- Sign up via Auth emulator
- Sign in and obtain idToken
- Create users/{uid} document in Firestore using authenticated request
- Verify UID-scoped security rules by attempting an unauthorized write

How to run
1) Start emulators in a separate terminal (from repo root):

```bash
firebase emulators:start --only firestore,auth --project demo-no-project
```

2) Run the harness (from repo root):

```bash
./scripts/run_auth_harness.sh
```

Custom host/project

You can override defaults with environment variables:

```bash
AUTH_EMULATOR_HOST=127.0.0.1:9099 FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_PROJECT=demo-no-project ./scripts/run_auth_harness.sh
```

Notes
- This harness uses the emulators' REST APIs and therefore does not require Flutter device/emulator plugin channels.
- The harness exits with non-zero status if a validation step fails.
- After Phase 1 is closed we can still add a companion set of `flutter test` mocks for fast CI-friendly UI verification.
