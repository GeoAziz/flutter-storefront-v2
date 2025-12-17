# CI Guidance for Firebase Emulator

## Overview
This document describes how to run Firebase emulator-backed tests locally and in CI. Sprint 1 includes:
- **Firestore cursor pagination integration test** (`test/firebase/firestore_cursor_pagination_integration_test.dart`): REST-based test that seeds 25 documents and validates cursor pagination (pages 10/10/5).
- **Sync status unit tests** (`test/providers/sync_status_manager_test.dart`): unit tests for SyncStatusNotifier and SyncManager status transitions.
- **Performance smoke test** (`test/performance/thumbnail_performance_test.dart`): verifies product list thumbnail scrolling frame rate.
- **GitHub Actions workflow** (`.github/workflows/firebase-emulator-tests.yml`): automatically starts emulator, runs tests with `FIREBASE_EMULATOR=true`, and stops emulator.

## Running Tests Locally

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Start Firestore emulator
```bash
firebase emulators:start --only firestore --project=demo-no-project &
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
```

### 3. Run emulator-gated integration tests
```bash
# Firestore cursor pagination test (requires running emulator)
FIREBASE_EMULATOR=true flutter test test/firebase/firestore_cursor_pagination_integration_test.dart -r expanded

# Sync status unit tests (no emulator required)
flutter test test/providers/sync_status_manager_test.dart -r expanded
```

### 4. Run performance smoke tests
```bash
flutter test test/performance/thumbnail_performance_test.dart -r expanded
```

### 5. Stop the emulator
```bash
firebase emulators:stop
```

## Running Tests in CI

The GitHub Actions workflow (`.github/workflows/firebase-emulator-tests.yml`) handles:
1. Install Flutter and firebase-tools
2. Start Firestore emulator in background
3. Wait for emulator to be ready on port 8080
4. Run all tests with `FIREBASE_EMULATOR=true` env var set
5. Stop the emulator
6. Report pass/fail

### Workflow Details
- **No authentication required** for emulator-only runs (uses demo project `demo-no-project`)
- **Port availability**: Firestore emulator uses port 8080 (ensure not in use before running)
- **Workflow file**: `.github/workflows/firebase-emulator-tests.yml` (triggered on push to main/feat branches or manual dispatch)

### Example: Trigger workflow manually
```bash
gh workflow run firebase-emulator-tests.yml
```

## Notes

- **REST-based emulator test**: `firestore_cursor_pagination_integration_test.dart` uses the Firestore Emulator REST API directly (no Firebase SDK required). This avoids platform-channel issues in headless test environments.
- **Performance profiling**: For detailed performance traces, use `flutter run --profile` and open DevTools Timeline tab. The smoke test provides a quick sanity-check only.
- **Emulator persistence**: Each test run in CI starts with a fresh emulator instance (no data persistence between jobs).
- **Debug logs**: Check `firestore-debug.log` or emulator UI (http://127.0.0.1:4001) for details during development.
