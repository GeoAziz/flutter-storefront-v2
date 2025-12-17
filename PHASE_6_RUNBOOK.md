# Phase 6 Runbook

This runbook describes how to run the Phase 6 headless validations (emulator-first) for the `flutter-storefront-v2` project.

Goals
- Validate webhook-driven finalize flows (simulated Stripe) end-to-end in local emulators.
- Ensure inventory reservations/finalize remain ACID-safe and audit/notification writes are produced only by functions.

Prerequisites
- Node.js (recommended 18.x or compatible with project's `functions/engines.node`).
- npm
- Firebase CLI (`firebase-tools`) installed globally or available via `npx`.
- Java (required by the Firestore emulator) — install default-jre if not present.

Emulator environment variables (for local runs)
- FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
- FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001

Notes on payment adapter
- The code uses a mock payment provider by default. If you set `STRIPE_API_KEY` in your environment and install the `stripe` package in `functions`, the runtime will prefer the Stripe provider — but do NOT add production keys to CI. This runbook assumes emulator/mock provider.

Files of interest
- `functions/index.js` — Functions runtime: reserve/finalize, webhook handler, audit & notification writer.
- `functions/lib/paymentProvider.js` — payment provider selection (mock vs Stripe).
- `functions/test/phase6_runner.js` — headless runner that seeds data, creates an order (triggering reservation), posts a simulated Stripe webhook to the Functions emulator, and asserts final state.

Quick local run (recommended)
1. Start emulators (separate terminal):

```bash
cd functions
npx firebase emulators:start --only firestore,functions
```

2. In another terminal, run the Phase 6 runner (emulator envs not required if using defaults above):

```bash
cd functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001 npm run test:phase6:all
```

Important implementation details
- The runner uses a polling mechanism (up to ~15s with 500ms intervals) instead of single short sleeps to wait for order `reserved` and `finalized` states. This improves determinism when emulators and function cold-starts vary.
- The runner now uses a per-run unique product id (e.g., `phase6-prod-<random>`) to avoid cross-run state pollution in the shared emulator environment.
- The runner no longer creates a `functionRequests` reserve request for reservation because the `reserveInventoryOnOrderCreate` Firestore trigger already performs reservation on order creation. Creating both caused double reservations.

CI integration notes
- A GitHub Actions workflow `phase6-ci.yml` is included to run the headless runner inside CI using emulators. The workflow starts the Firestore & Functions emulators, waits until they are ready, and runs `npm run test:phase6:all` under `functions/`.
- The CI job uses emulator-only (mock) payment provider; it does not require network access or real Stripe keys.

Troubleshooting
- If the runner times out waiting for status transitions increase the polling timeout in `functions/test/phase6_runner.js`.
- If emulator startup fails in CI, ensure `firebase-tools` and Java are available in the runner image or install them as part of the workflow.

Next steps
- Merge the feature branch that contains the Phase 6 fixes and CI workflow.
- Optionally upgrade `firebase-functions` to >=5.1.0 in `functions/package.json` and run the suite locally to verify compatibility.

Contact
- If anything flaps on CI, the simplest immediate mitigation is to increase the polling timeouts in the runner and re-run until the emulator cold-start window is stable for your runner image.

