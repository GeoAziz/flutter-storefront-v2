# Automated Testing & Verification Guide

This document describes how to run automated tests and validation checks for the flutter-storefront-v2 app to quickly verify backend integration before proceeding to Week 2 UI development.

## Overview

The automated testing script (`scripts/automated_test.sh`) validates:
1. **Project Structure** — ensures all required files and directories exist
2. **Dependencies** — checks and updates Flutter dependencies
3. **Static Analysis** — runs `flutter analyze` for code quality
4. **Firestore Rules** — validates rules syntax
5. **Cloud Functions** — checks function definitions
6. **Build Compilation** — (optional) ensures app can build
7. **Emulator Integration** — verifies local emulator connectivity and basic operations

## Quick Start

### 1. Ensure Emulators Are Running

In one terminal, start the Firebase emulators:

```bash
cd /path/to/flutter-storefront-v2
firebase emulators:start --only functions,firestore
```

You should see output like:
```
✔  All emulators ready!
┌───────────┬────────────────┬──────────────────────────┐
│ Functions │ 127.0.0.1:5001 │ http://127.0.0.1:4000... │
│ Firestore │ 127.0.0.1:8080 │ http://127.0.0.1:4000... │
└───────────┴────────────────┴──────────────────────────┘
```

### 2. Run the Automated Test Suite

In a new terminal, from the project root:

```bash
./scripts/automated_test.sh
```

This runs all phases and outputs a summary.

### 3. Run the App Locally

Once tests pass:

```bash
flutter run
```

The app will boot with emulator configuration enabled (in debug mode) and connect to:
- Firestore: `127.0.0.1:8080`
- Functions: `127.0.0.1:5001` (when firebase_functions package is added)

## Script Usage

### Basic Run (all phases)

```bash
./scripts/automated_test.sh
```

### Skip Build Compilation

If you're in a headless environment or want to skip the build step:

```bash
./scripts/automated_test.sh --no-build
```

### Run Static Analysis Only

For quick checks without emulator interaction:

```bash
./scripts/automated_test.sh --analyze-only
```

### Require Emulator (fail if not running)

To ensure tests fail fast if emulator is not running:

```bash
./scripts/automated_test.sh --emulator-only
```

## What the Script Does

### Phase 1: Pre-flight Checks
- Verifies `pubspec.yaml`, `firebase.json`, `lib/`, `functions/` exist
- Checks Firebase Emulator connectivity (8080, 5001)
- Warns if emulators are not running

### Phase 2: Static Analysis
- Runs `flutter format` check
- Runs `flutter analyze` for code quality
- Updates dependencies with `flutter pub get`

### Phase 3: Firestore Rules Validation
- Checks `lib/config/firestore.rules` exists
- Attempts to validate rules syntax using Firebase CLI (if possible)

### Phase 4: Cloud Functions Check
- Verifies `functions/index.js` contains:
  - `rateLimitedWrite` function
  - `batchWrite` function
- Checks `functions/package.json` exists

### Phase 5: Build Compilation (optional, slow)
- Attempts to build the app in debug mode
- Can be skipped with `--no-build` flag

### Phase 6: Integration Test
- Tests Firestore Emulator API connectivity
- Tests Functions Emulator API connectivity
- Queries Emulator for collections (basic connectivity check)

### Phase 7: Summary & Next Steps
- Prints results and recommendations

## Manual Testing Checklist

After the automated script passes, run the app and manually test:

- [ ] **Auth Flow**
  - Sign up with email/password
  - Verify user document created in Firestore
  - Log out and log back in

- [ ] **Product Listing**
  - View products (Firestore read)
  - Verify products appear on home screen
  - Check Firestore collections in Emulator UI

- [ ] **Cart Operations**
  - Add product to cart (Firestore write)
  - View cart
  - Update quantities
  - Remove items

- [ ] **Order Placement**
  - Go through checkout
  - Place order (transaction)
  - Verify order document created in Firestore

- [ ] **Offline Sync** (if implemented)
  - Perform an action offline (with network disabled)
  - Go back online
  - Verify action synced to Firestore

## Emulator Monitoring

While testing, monitor the Emulator UI in your browser:

```
http://127.0.0.1:4000/
```

This shows:
- **Firestore**: Collections, documents, and real-time data changes
- **Functions**: Logs from Cloud Functions invocations
- **Rules Violations**: Security rule rejections (if any)

## Troubleshooting

### Emulator Not Running
```bash
# Check if ports are in use
lsof -i :8080  # Firestore
lsof -i :5001  # Functions

# Kill any blocking process and restart
firebase emulators:start --only functions,firestore
```

### Build Fails
- Ensure Flutter SDK is up to date: `flutter upgrade`
- Clear build cache: `flutter clean && flutter pub get`
- Check for platform-specific issues (Android SDK, iOS Xcode)

### Firestore Rules Validation Fails
- Check `lib/config/firestore.rules` syntax
- Use the Emulator UI to test rules with simulated reads/writes
- Refer to Firebase docs: https://firebase.google.com/docs/firestore/security/rules-structure

### App Can't Connect to Emulator
- Verify emulator is running: `curl http://127.0.0.1:8080`
- Ensure app has `kDebugMode` check in `main.dart` for `setupEmulators()`
- Check logs in app console for emulator setup messages

## Continuous Integration

To run this script in CI/CD pipelines (GitHub Actions, etc.):

```yaml
# Example GitHub Actions workflow
- name: Run Automated Tests
  run: |
    firebase emulators:start --only functions,firestore &
    sleep 5
    ./scripts/automated_test.sh --no-build
```

## Next Steps

Once automated tests pass and manual testing is complete:

1. ✅ Backend integration verified
2. 📋 **Week 2: UI Integration** — Wire Riverpod providers to screens
3. 🚀 **Deployment** — Deploy to Firebase project
4. 📊 **Monitoring** — Set up alerts and dashboards

## Contact & Support

For issues or questions:
- Check Firestore rules syntax: [Firebase Docs](https://firebase.google.com/docs/firestore/security/rules-structure)
- Cloud Functions: [Firebase Docs](https://firebase.google.com/docs/functions)
- Flutter Riverpod: [Official Docs](https://riverpod.dev)
