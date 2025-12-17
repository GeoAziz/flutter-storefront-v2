# Mocked Tests (Option B)

## Overview

This document describes the mocked flutter_test harness (Option B) for fast, deterministic testing of auth-related flows without requiring a device or emulator.

### Why mocked tests?

- **Speed**: Run under `flutter test` without device startup overhead (seconds vs. minutes).
- **Determinism**: No emulator variance or timing dependencies.
- **CI-friendly**: Perfect for PR feedback on auth screens and flows.
- **Complement to headless harness**: The headless harness validates Firestore writes and security rules via REST; mocked tests validate auth UI flows and provider integration.

## Test files

### 1. `test/unit/auth_controller_mock_test.dart`

Unit test for the `AuthController` using `MockFirebaseAuth`.

**What it tests:**
- `AuthController.signIn` with mocked Firebase Auth
- User creation and credential verification

**How it works:**
- Creates a mock user with `MockFirebaseAuth`
- Uses Riverpod `ProviderContainer` with provider overrides to inject the mock
- Calls `authController.signIn()` and asserts the returned credential

**Run it:**
```bash
flutter test test/unit/auth_controller_mock_test.dart
```

Expected output: `✓ AuthController.signIn signs in existing user`

### 2. `test/widget/login_screen_mock_test.dart`

Widget test for the login screen with mocked Firebase Auth and provider overrides.

**What it tests:**
- `LoginScreen` renders correctly
- User input (email/password) is captured
- Tap login button triggers sign-in
- Navigation to `RouteNames.entryPoint` on success

**How it works:**
- Creates a test user with `MockFirebaseAuth`
- Wraps the screen in `ProviderScope` with an override for `firebaseAuthProvider` → mock
- Uses `tester` to pump widgets, enter text, and tap buttons
- Asserts that navigation succeeds

**Run it:**
```bash
flutter test test/widget/login_screen_mock_test.dart
```

Expected output: `✓ LoginScreen signs in and navigates to entryPoint`

## Running all mocked tests

```bash
flutter test test/unit/ test/widget/
```

Or simply:

```bash
flutter test
```

This will run all tests in the `test/` directory (unit + widget).

## Dev dependencies

The mocked tests require `firebase_auth_mocks ^0.13.0` as a dev dependency in `pubspec.yaml`.

### Why not mock Firestore too?

The `cloud_firestore ^4.x` runtime dependency conflicts with older `fake_cloud_firestore` packages. Instead:

- **Firestore writes & rules**: Validated by the headless harness (`scripts/auth_harness.dart`), which uses REST endpoints.
- **Auth flows**: Mocked via `MockFirebaseAuth`.
- **Separation of concerns**: Unit/widget tests validate UI logic; the headless harness validates backend correctness.

## CI integration

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs:

1. Headless harness: `bash scripts/run_auth_harness.sh`
   - Validates Auth + Firestore writes/reads/rules via REST
2. Mocked tests: `flutter test`
   - Validates auth UI flows and provider integration

Together, these provide fast PR feedback without requiring a device or full emulator.

## Expected test results

Both tests should **pass** under `flutter test` with no device/emulator:

```
✓ AuthController.signIn signs in existing user (test/unit/auth_controller_mock_test.dart)
✓ LoginScreen signs in and navigates to entryPoint (test/widget/login_screen_mock_test.dart)

====== 2 passed in 0.5s ======
```

## Troubleshooting

### Import errors on `firebase_auth_mocks`

If you see `Target of URI doesn't exist: 'package:firebase_auth_mocks/...'`:

1. Run `flutter pub get` to fetch dependencies.
2. Check that `firebase_auth_mocks: ^0.13.0` is in `pubspec.yaml` dev_dependencies.

### Test fails with "No such named parameter: email"

This usually means the mock package version is incompatible. Verify:
- `firebase_auth: ^4.14.0` (runtime)
- `firebase_auth_mocks: ^0.13.0` (dev)

If `flutter pub add dev:firebase_auth_mocks` suggests a different version, use that.

### Widget test fails with "Unable to establish connection on channel"

This error occurs when trying to use real Firebase plugins inside `flutter test`. Our mocked tests avoid this by using `MockFirebaseAuth` instead. If a test still fails with this, check that:
- The test doesn't import real Firebase packages directly (only `firebase_auth_mocks`).
- Provider overrides are correctly applied via `ProviderScope(overrides: [...])`.

## Future enhancements

- Add more widget tests (signup screen, profile screen, etc.) using similar patterns.
- Consider adding a lightweight in-repo Firestore fake if deeper Firestore mocking is needed (currently deferred).
- Integrate signup/signout flows once UI screens are finalized.

## Related artifacts

- **Headless harness**: `scripts/auth_harness.dart` (validates Auth + Firestore via REST)
- **Harness runner**: `scripts/run_auth_harness.sh`
- **Harness docs**: `docs/HARNESS.md`
- **CI workflow**: `.github/workflows/ci.yml`
