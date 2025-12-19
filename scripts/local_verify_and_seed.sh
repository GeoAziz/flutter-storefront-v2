#!/usr/bin/env bash
# Local verification helper
# Run this on your development machine (where the Firestore emulator and
# Flutter/Dart SDK are installed). It will perform the verification steps
# requested earlier, optionally run the admin seeder if the products
# collection is empty, run tests, and write a log file `verification.log`.

set -u

OUT=verification.log
rm -f "$OUT"
echo "Local verification run: $(date --iso-8601=seconds)" | tee -a "$OUT"

echo "\n=== 1) Check emulator (port 8080) ===" | tee -a "$OUT"
if lsof -i :8080 >/dev/null 2>&1; then
  echo "Emulator appears to be RUNNING on :8080" | tee -a "$OUT"
else
  echo "Emulator not detected on :8080." | tee -a "$OUT"
  echo "Start it in another terminal: firebase emulators:start --only firestore" | tee -a "$OUT"
fi

echo "\n=== 2) Query products collection (poafix) ===" | tee -a "$OUT"
export FIRESTORE_EMULATOR_HOST=${FIRESTORE_EMULATOR_HOST:-127.0.0.1:8080}
COUNT=$(curl -s "http://127.0.0.1:8080/v1/projects/poafix/databases/(default)/documents/products?pageSize=3" | jq '.documents | length' 2>/dev/null || echo "-")
echo "poafix products count (first page): $COUNT" | tee -a "$OUT"

echo "\n=== 3) Show example document fields ===" | tee -a "$OUT"
EXAMPLE_ID=${EXAMPLE_ID:-p_1766155658359_0}
DOC=$(curl -s "http://127.0.0.1:8080/v1/projects/poafix/databases/(default)/documents/products/${EXAMPLE_ID}" | jq '.fields' 2>/dev/null || echo "null")
echo "fields for ${EXAMPLE_ID}:" | tee -a "$OUT"
echo "$DOC" | tee -a "$OUT"

# Optionally seed if empty
SEED_IF_EMPTY=${SEED_IF_EMPTY:-true}
if [ "$SEED_IF_EMPTY" = "true" ] && { [ "$COUNT" = "0" ] || [ "$COUNT" = "-" ]; }; then
  echo "\nProducts collection appears empty. Running admin seeder..." | tee -a "$OUT"
  # Ensure node deps
  if [ -f package.json ]; then
    echo "Installing npm deps (may take a minute)..." | tee -a "$OUT"
    npm install --no-audit --no-fund 2>&1 | tee -a "$OUT" || echo "npm install failed" | tee -a "$OUT"
  fi
  echo "Running admin seeder to write 10 products to poafix..." | tee -a "$OUT"
  USE_ADMIN_SEEDER=true FIRESTORE_EMULATOR_HOST=$FIRESTORE_EMULATOR_HOST bash scripts/run_seed_products.sh poafix 10 2>&1 | tee -a "$OUT" || echo "Seeder failed" | tee -a "$OUT"
  # Re-query count
  COUNT=$(curl -s "http://127.0.0.1:8080/v1/projects/poafix/databases/(default)/documents/products?pageSize=3" | jq '.documents | length' 2>/dev/null || echo "-")
  echo "post-seed poafix products count (first page): $COUNT" | tee -a "$OUT"
fi

echo "\n=== 4) Run repository-level quick test (dart) ===" | tee -a "$OUT"
if command -v dart >/dev/null 2>&1; then
  echo "Running test_firestore.dart (one-off)..." | tee -a "$OUT"
  dart test_firestore.dart 2>&1 | tee -a "$OUT" || echo "dart test failed (see above)" | tee -a "$OUT"
else
  echo "dart not found in PATH; skipping dart test" | tee -a "$OUT"
fi

echo "\n=== 5) Run Flutter tests and analyzer ===" | tee -a "$OUT"
if command -v flutter >/dev/null 2>&1; then
  echo "Running flutter pub get..." | tee -a "$OUT"
  flutter pub get 2>&1 | tee -a "$OUT" || echo "pub get failed" | tee -a "$OUT"

  echo "Running flutter test (may take some time)" | tee -a "$OUT"
  flutter test --no-pub 2>&1 | tee -a "$OUT" || echo "flutter test had failures" | tee -a "$OUT"

  echo "Running flutter analyze" | tee -a "$OUT"
  flutter analyze --no-pub 2>&1 | tee -a "$OUT" || echo "analyze found issues" | tee -a "$OUT"
else
  echo "flutter not found in PATH; skipping flutter tests/analyze" | tee -a "$OUT"
fi

echo "\n=== 6) Run verify_flow.sh ===" | tee -a "$OUT"
if [ -x ./verify_flow.sh ]; then
  ./verify_flow.sh 2>&1 | tee -a "$OUT" || echo "verify_flow had failures" | tee -a "$OUT"
else
  echo "verify_flow.sh not executable or missing; created earlier" | tee -a "$OUT"
fi

echo "\nLocal verification finished. Log: $OUT" | tee -a "$OUT"
echo "Tail of log:" | tee -a "$OUT"
tail -n 200 "$OUT" | sed -n '1,200p'

exit 0
