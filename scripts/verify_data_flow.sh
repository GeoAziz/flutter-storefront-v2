#!/usr/bin/env bash
set -euo pipefail
HOST=${EMULATOR_HOST:-127.0.0.1}
PORT=${EMULATOR_PORT:-8080}

echo "1) Provider wiring check"
grep -n "FirestoreProductRepository" lib/providers/repository_providers.dart || true

echo "\n2) Firestore data check"
if curl -s "http://${HOST}:${PORT}/v1/projects/demo-project/databases/(default)/documents/products?pageSize=1" | jq '.documents | length' >/dev/null 2>&1; then
  docs=$(curl -s "http://${HOST}:${PORT}/v1/projects/demo-project/databases/(default)/documents/products?pageSize=1" | jq '.documents | length')
  if [ "$docs" -gt 0 ]; then
    echo "✓ Firestore has data (documents: $docs)"
  else
    echo "✗ Firestore empty (0 documents)"
  fi
else
  echo "Warning: Could not query Firestore emulator at ${HOST}:${PORT}"
fi

echo "\n3) Static analysis (best-effort)"
if command -v flutter >/dev/null 2>&1; then
  flutter analyze --no-pub || echo "flutter analyze failed or produced issues"
else
  echo "flutter CLI not found; skip analyze"
fi

echo "\n4) Run a couple of unit tests (if Flutter available)"
if command -v flutter >/dev/null 2>&1; then
  flutter test --no-pub || echo "flutter test failed"
else
  echo "flutter CLI not found; skip tests"
fi
