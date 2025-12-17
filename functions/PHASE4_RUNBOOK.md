# Phase 4: Authorization, Hardening, and Production Readiness (Spark-Safe)

Purpose
- Enforce role-based access control (user/admin) and prove the system is safe to run.
- Add limited, controlled admin mutations with audit logging.
- All validation is script-driven and headless.

Emulator prerequisites
- Start the Firestore emulator from the project root:

```bash
firebase emulators:start --only firestore
```

Canonical one-liner (run from project root)

```bash
cd functions && npm install && npm run test:phase4:all
```

What the runner does (execution order)
1. **Auth matrix validation** — proves user cannot read/write admin collections; admin can.
2. **Admin mutations validation** — proves admin can update products and inventory; validates state changes.
3. **Audit log validation** — proves critical actions are logged as append-only entries.

PASS definition
- The runner prints `✅ Phase 4 runner: ALL SCRIPTS PASSED` and exits `0` when all assertions succeed.
- Any failure prints a clear `❌ ... FAIL` and exits non-zero immediately (fail-fast), suitable for CI.

Authorization model
- **User role**: can read own orders/cart, cannot access inventory or admin collections.
- **Admin role**: can read all collections, can update products/inventory, can read audit logs.
- Enforced via Firestore security rules (file: `lib/config/firestore.rules`).

Admin mutations (controlled)
- Update product active flag (e.g., for archiving/publishing).
- Adjust inventory stock (e.g., for corrections or restocking).
- No deletes allowed; blast radius is minimal.

Audit logging (lightweight)
- `auditLog` collection stores critical events: inventory adjustments, product updates, order status changes.
- Append-only: no deletes or updates via rules.
- Admin-readable only.
- No external exports; Spark-plan safe.

Warnings & boundaries
- These scripts are emulator-only and Spark-plan safe. Do NOT run them against production Firestore.
- No real payments, no FCM, no cloud schedulers, no Blaze features.
- This is about control and correctness, not new features.

Out of scope (intentionally not in Phase 4)
- Real payment provider integrations
- FCM or email notifications
- Background schedulers or triggered cloud functions
- Blaze plan upgrades
- UI-driven admin pages (read-only admin dashboard from Phase 3 is sufficient)

If you want CI integration, ensure the CI job starts the Firestore emulator before running the one-liner above.
