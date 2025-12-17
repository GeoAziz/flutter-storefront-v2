#!/usr/bin/env bash
set -euo pipefail

# Wrapper to run the Dart seed script. Prefers system 'dart' if available.
PROJECT=${1:-}
COUNT=${2:-30}

if command -v dart >/dev/null 2>&1; then
  dart scripts/seed_products.dart --project ${PROJECT:-demo-project} --count ${COUNT}
else
  echo "System 'dart' not found. Attempting to run with 'flutter' bundled dart."
  flutter pub get
  FLUTTER_DART=$(flutter --version >/dev/null 2>&1 && echo "$(flutter sdk-path)/bin/cache/dart-sdk/bin/dart")
  if [ -x "$FLUTTER_DART" ]; then
    "$FLUTTER_DART" scripts/seed_products.dart --project ${PROJECT:-demo-project} --count ${COUNT}
  else
    echo "Unable to find dart executable. Install Dart or ensure Flutter is available." >&2
    exit 2
  fi
fi
