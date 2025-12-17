#!/usr/bin/env bash
# Run the headless auth + firestore harness against local emulators.
# Usage: ./scripts/run_auth_harness.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Allow overrides via env
: "${AUTH_EMULATOR_HOST:=127.0.0.1:9099}"
: "${FIRESTORE_EMULATOR_HOST:=127.0.0.1:8080}"
: "${FIREBASE_PROJECT:=demo-no-project}"

echo "Using Auth emulator: http://$AUTH_EMULATOR_HOST"
echo "Using Firestore emulator: http://$FIRESTORE_EMULATOR_HOST"
echo "Project: $FIREBASE_PROJECT"

echo "Running harness..."
# Run the Dart script. Prefer system `dart` if available; otherwise use the
# Dart SDK bundled with the `flutter` tool.
if command -v dart >/dev/null 2>&1; then
  dart run scripts/auth_harness.dart
else
  echo "system 'dart' not found — falling back to Flutter's embedded Dart SDK"
  # Ensure dependencies are fetched so scripts can import packages
  flutter pub get
  FLUTTER_BIN="$(command -v flutter || true)"
  if [ -z "$FLUTTER_BIN" ]; then
    echo "flutter not found in PATH — please install Flutter or make 'dart' available." >&2
    exit 2
  fi
  FLUTTER_ROOT="$(dirname "$(dirname "$FLUTTER_BIN")")"
  DART_BIN="$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart"
  if [ ! -x "$DART_BIN" ]; then
    echo "Embedded dart not found at $DART_BIN" >&2
    exit 3
  fi
  "$DART_BIN" run scripts/auth_harness.dart
fi

EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
  echo "Harness completed successfully"
else
  echo "Harness failed with exit code $EXIT_CODE"
fi
exit $EXIT_CODE
