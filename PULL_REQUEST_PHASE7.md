# PR: phase7 — Idempotent Webhook Handling

## Summary
This PR merges `feature/phase6-runner-stability` into `main` and contains the Phase 7 implementation for idempotent webhook handling.

Key deliverables in this branch:
- Transaction-based `webhookEvents/{eventId}` creation for atomic deduplication
- Finalization guard in `performInventoryFinalize` to prevent double-finalize
- Safe `FieldValue` access fallbacks for emulator compatibility
- Append-only audit logging with `eventId` tracking
- `functions/test/phase7_runner.js` — headless deterministic runner that simulates duplicate webhooks
- `.github/workflows/phase7-ci.yml` — CI workflow that runs emulator-based tests (Node 18.x and 20.x)
- Comprehensive documentation: `PHASE_7_RUNBOOK.md`, `PHASE_7_COMPLETION_SUMMARY.md`, `PHASE_7_STATUS_DASHBOARD.md`, `PHASE_7_QUICK_REFERENCE.md`, `PHASE_7_DOCUMENTATION_INDEX.md`

---

## Why this should be merged
- Eliminates a high-risk class of production bugs (duplicate webhook double-finalization)
- Ensures deterministic, emulator-first test coverage for webhook flows
- Adds CI enforcement to prevent regressions
- Extensive documentation included for operational handoff

---

## PR Checklist (must be green before merge)
- [ ] All CI checks pass (phase7-ci workflow)
  - Node 18.x and 20.x matrix both successful
- [ ] Manual smoke tests executed locally (see steps below)
- [ ] Documentation reviewed and approved (runbook + quick ref)
- [ ] Code review sign-offs from backend and QA
- [ ] Rollback plan prepared and noted in PR description

---

## Quick Manual Smoke Test (Run locally before merging)
1. Start emulators:

```bash
firebase emulators:start --only functions,firestore &
```

2. In `functions/` run Phase 7 runner:

```bash
cd functions
npm run test:phase7:all
```

3. Confirm output includes:
- `✅ Phase 7 runner: ALL TESTS PASSED`
- `webhookEvents` doc created and `processed: true`
- Audit log has a single entry for the test eventId

4. (Optional) Run Phase 6 & 5 runners:

```bash
npm run test:phase6:all
npm run test:phase5:all
```

---

## Rollback Plan
If any production issue occurs after deploy:
1. Immediately run `firebase functions:shell` or disable the function by deploying a safe noop function version.
2. Revert `main` to previous commit and re-deploy the prior functions version: `git checkout <previous-sha> && firebase deploy --only functions`.
3. Investigate audit logs and revert any stateful changes as needed (inventory adjustments tracked in auditLog).

---

## Production Monitoring (first 24–72h)
- Monitor `functions` Cloud Logs for `Duplicate event detected` messages and any unexpected errors.
- Monitor `auditLog` for `eventId` entries: ensure exactly one finalization entry per eventId.
- Monitor order counts/throughput and inventory snapshots for anomalies.

---

## Approvers
- Backend: @backend-owner
- QA: @qa-owner
- DevOps: @devops-owner
- Product (optional): @product-owner

---

## Suggested PR Description for GitHub UI
```
phase7: idempotent webhook handling

Implements transaction-based deduplication for Stripe webhooks via webhookEvents/{eventId} documents.
Adds finalization guard, audit logging with eventId, and headless test runner verification. CI workflow added to run emulator-based tests headlessly across Node 18 and 20.

See: PHASE_7_RUNBOOK.md for architecture and operational details.
```

---

If you want, I can:
- Create and open the PR using the GitHub CLI (`gh pr create`) if you give me permission to run commands here, or
- Provide the exact `gh` command you can run locally to open the PR with this body.
