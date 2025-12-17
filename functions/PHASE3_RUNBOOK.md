# Phase 3: Headless validation runbook

Purpose
- Provide a single, deterministic, headless entry point to validate Phase 3 behaviors (Inventory, Payments simulator, Notifications stub) against the Firestore emulator.

Emulator prerequisites
- Install Firebase CLI and start the Firestore emulator from the project root:

```bash
firebase emulators:start --only firestore
```

Canonical one-liner (run from project root)

```bash
cd functions && npm install && npm run test:phase3:all
```

What the runner does (order)
1. Inventory flow: seeds inventory and runs reserve → release → finalize scenarios (asserts expected state changes).
2. Payments simulator: creates two orders; simulates a successful and a failed payment via a mock adapter and updates order status accordingly.
3. Notifications simulator: emits order_placed and order_completed events to a console/log sink and verifies `notifications_log` entries.

PASS definition
- The runner prints `✅ Phase 3 runner: ALL SCRIPTS PASSED` and exits `0` when all steps' assertions succeed.
- Any failure prints a clear `❌ ... FAIL` and exits non-zero immediately (fail-fast), suitable for CI.

Warnings & boundaries
- These scripts are emulator-only and Spark-plan safe. Do NOT run them against production Firestore.
- No real payments, no FCM, no external webhooks, no UI runs. This runbook is intentionally minimal and deterministic.

Out of scope
- UI/device-driven validation
- Real payment provider integrations
- Production deployments or cloud scheduler usage

If you want CI integration, ensure the CI job starts the Firestore emulator before running the one-liner above.
