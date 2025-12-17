# Phase 7: Idempotent Webhook Handling - Runbook

## Overview

Phase 7 implements **idempotent webhook handling** for Stripe payment webhooks. This ensures that even if Stripe delivers the same webhook event multiple times (due to network retries or system redundancy), the order finalization process executes exactly once.

**Key Achievement**: Duplicate webhook events are automatically detected and deduplicated, preventing double-charging and inventory inconsistencies.

---

## Architecture

### Webhook Idempotency Contract

1. **Event Deduplication**: Each webhook event (identified by `eventId` from Stripe) is recorded in a `webhookEvents/{eventId}` Firestore document.
2. **Transaction Atomicity**: The first webhook creates the `webhookEvents` doc via Firestore transaction; subsequent duplicates fail the transaction and return early.
3. **Finalization Guard**: `performInventoryFinalize` checks if the order is already finalized (`status === 'finalized'`) and returns early if so.
4. **Audit Trail**: All webhook processing attempts are logged to the audit collection with the `eventId`, result, and timestamp.

### Collections

#### `webhookEvents`
- **Purpose**: Track processed Stripe webhook events
- **Structure**:
  ```
  webhookEvents/{eventId}
  ├── receivedAt: timestamp
  ├── eventType: string (e.g., "payment_intent.succeeded")
  ├── orderId: string
  ├── processed: boolean
  └── finalizeResult: object (success status and inventory details)
  ```
- **Lifecycle**: Created atomically on first webhook delivery; subsequent duplicates skip creation
- **TTL**: Not yet implemented; future enhancement with Firestore TTL policy (7 days)

#### `orders` (updates)
- **Added field**: `webhookEventId: string` — tracks the Stripe eventId that finalized this order
- **Status transitions**: `pending` → `reserved` (trigger) → `finalized` (webhook)

#### `auditLog` (updates)
- **New fields**:
  - `eventId: string` — Stripe webhook eventId (for tracing duplicates)
  - `webhookProcessed: boolean` — whether this audit entry was for a webhook
  - `result: string` — 'first_time_finalized' | 'duplicate_detected' | 'already_finalized' | 'error'

---

## Local Development & Testing

### Prerequisites

1. **Node.js** (18.x or 20.x recommended)
2. **Firebase CLI** (installed globally)
3. **Emulators** running locally (Firestore + Functions)

### Running the Phase 7 Emulator Tests

#### Option 1: Run Phase 7 tests only
```bash
cd functions
npm run test:phase7:all
```

#### Option 2: Run all phases (5–7)
```bash
cd functions
npm run test:all
```

#### Option 3: Run individual test file
```bash
cd functions
node test/phase7_runner.js
```

### Test Output Interpretation

```
✅ Phase 7 runner: ALL TESTS PASSED
```

**Green indicators**:
- `[phase7] Inventory correct after single finalize`: Confirms order reserved qty decremented only once
- `[phase7] webhookEvents processed: true`: Confirms `webhookEvents` doc was created
- `[phase7] Audit entries for eventId: 1`: Confirms exactly one audit log for the eventId (duplicate was detected early)
- `[phase7] Notifications for system: 1`: Confirms notification was written once

**Red indicators** (if any):
- `AssertionError: expected X to equal Y` — Inventory or audit count mismatch (typically means duplicate finalize occurred)
- `Cannot read properties of undefined (reading 'FieldValue')` — FieldValue access issue (check safe fallback logic)
- `Duplicate event detected` — Expected behavior (not an error); means idempotency guard worked

### Environment Variables for Local Testing

```bash
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
export FUNCTIONS_EMULATOR_HOST=127.0.0.1:5001
export GCLOUD_PROJECT=demo-no-project
```

**Note**: The emulator defaults to `demo-no-project` unless overridden. Functions code uses `process.env.GCLOUD_PROJECT || 'demo-project'` for compatibility.

---

## CI/CD Integration

### GitHub Actions Workflow

File: `.github/workflows/phase7-ci.yml`

**Execution Flow**:
1. Checkout code
2. Setup Node.js (matrix: 18.x, 20.x)
3. Install Firebase CLI
4. Install functions dependencies
5. Start Firestore + Functions emulators in background
6. Run Phase 7 tests (idempotent webhooks)
7. Run Phase 6 baseline tests (payment webhooks)
8. Run Phase 5 baseline tests (audit logging)
9. Cleanup emulators

**Trigger Events**:
- Push to `main`, `develop`, or `feature/**` branches
- Pull requests targeting `main`

**Status Check**:
- Workflow fails if any test suite returns non-zero exit code
- Workflow passes only if all three phases (5, 6, 7) pass

### Running CI Locally

To simulate CI environment locally:

```bash
cd /path/to/flutter-storefront-v2
firebase emulators:start --only functions,firestore &

# In another terminal:
cd functions
npm run test:phase7:all
npm run test:phase6:all
npm run test:phase5:all

pkill -f "firebase emulators"
```

---

## Webhook Processing Flow

### First Webhook Delivery (Happy Path)

1. **Stripe posts** webhook to `/stripeWebhook` with `eventId = "evt_123abc"`
2. **Handler logs** webhook receipt: `✅ [Webhook] First-time event recorded`
3. **Transaction attempt**:
   - Create `webhookEvents/evt_123abc` with `receivedAt`, `eventType`, `orderId`
   - If create succeeds, continue to finalization
   - If create fails (duplicate), catch and return early
4. **Finalize order**: Call `performInventoryFinalize`
   - Decrement `product.reserved` and `inventory.reserved` atomically
   - Set `order.status = 'finalized'`
   - Write audit log with `eventId` and result
   - Write notification (optional FCM/email later)
5. **Update webhookEvents**: Set `processed: true`, `finalizeResult: { ... }`
6. **Return** 200 OK to Stripe

### Duplicate Webhook Delivery (Idempotency)

1. **Stripe redelivers** webhook with same `eventId = "evt_123abc"`
2. **Handler logs** webhook receipt: `🔁 [Webhook] Duplicate event detected: evt_123abc`
3. **Transaction attempt**:
   - Try to create `webhookEvents/evt_123abc` again
   - **Transaction fails** because doc already exists (transaction.create() enforces new-doc-only)
   - Catch `Error` and check if `message.includes('already')`
4. **Early return** with message: `{ success: true, message: 'duplicate_event_detected' }`
5. **No finalization** performed (order already finalized from first webhook)
6. **Return** 200 OK to Stripe (Stripe sees success, stops retrying)

### Order Already Finalized Guard (Edge Case)

If somehow a webhook bypasses the `webhookEvents` dedup and reaches `performInventoryFinalize`:

1. **Guard check**: `if (order.status === 'finalized') { return { ... }; }`
2. **Return early** without decrementing inventory again
3. **Log** to audit: result = 'already_finalized'
4. **No side effects** on order or inventory

---

## Test Event IDs & Scenarios

### Phase 7 Test Suite

The Phase 7 runner (`functions/test/phase7_runner.js`) exercises:

1. **Setup**:
   - Seed product: name = "Test Idempotent Widget", stock = 50, reserved = 0
   - Create order: qty = 3, status = "pending"
   - Trigger reservation: status transitions to "reserved" (via function trigger or inline fallback)

2. **First Webhook**:
   - Event ID: `phase7-<random>-evt1`
   - Type: `charge.succeeded`
   - Expected: Order finalized, stock = 47, reserved = 0, webhookEvents doc created

3. **Duplicate Webhook**:
   - Same event ID as first
   - Sent immediately after first webhook
   - Expected: Detected as duplicate, no finalization, audit log shows "duplicate_detected"

4. **Assertions**:
   - `stock === 47` (only one decrement)
   - `reserved === 0` (order fully finalized, not stuck in reserved state)
   - `webhookEvents[eventId].processed === true`
   - Audit log has exactly 1 entry for the eventId (duplicate not logged as separate event)
   - Notification written exactly once

---

## Monitoring & Debugging

### Console Output Markers

| Emoji | Meaning | Example |
|-------|---------|---------|
| ✅ | First webhook processed successfully | `✅ [Webhook] First-time event recorded` |
| 🔁 | Duplicate webhook detected | `🔁 [Webhook] Duplicate event detected: evt_123` |
| ⚠️ | Webhook error or warning | `⚠️ [Webhook] Failed to ...` |

### Firestore Console

In Firebase Console (or emulator UI):
- Navigate to `webhookEvents` collection
- Look for documents with your `eventId`
- Each should have:
  - `receivedAt: timestamp`
  - `processed: true`
  - `finalizeResult: { ... }`

### Audit Log

In Firebase Console → `auditLog`:
- Filter by `eventId = "evt_123abc"`
- Should see exactly 1 entry (not 2, even if webhook was sent twice)
- `result` field shows `'first_time_finalized'` or `'duplicate_detected'`

---

## Production Considerations

### Environment Variables

```bash
# Production (real Stripe):
GCLOUD_PROJECT=e-commerce-prod-project
STRIPE_WEBHOOK_SECRET=whsec_live_xxx
FIRESTORE_EMULATOR_HOST=  # unset (use real Firestore)

# Local development:
GCLOUD_PROJECT=demo-no-project
STRIPE_WEBHOOK_SECRET=whsec_test_xxx
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
```

### Real Stripe Integration

1. **Webhook Secret**: Obtain from Stripe Dashboard > Developers > Webhooks
2. **Event Types**: Subscribe to:
   - `charge.succeeded` (finalize order, decrement inventory)
   - `charge.refunded` (restore inventory, mark order as refunded) — *Phase 8*
3. **Retry Policy**: Stripe retries for 3 days; idempotency guard ensures safety
4. **Signed Verification**: Use `stripe.webhooks.constructEvent()` with secret (already implemented)

### Firestore TTL & Pruning

- **Current**: `webhookEvents` docs live indefinitely
- **Future Enhancement**: Add TTL policy (7 days) via Firestore admin panel
  - Click `webhookEvents` collection → Expiration Policies → Set to 7 days on all docs
  - Or: Use scheduled function to delete docs older than 7 days

### Notifications

- **Current State**: `writeNotification(...)` called but no provider wired
- **Future Integration**:
  - FCM: Send push notifications to user's device
  - Email: Send order confirmation email
  - SMS: Send order status SMS (optional)
- **Guidance**: See PHASE_8_NOTIFICATIONS_PLAN.md (TBD)

---

## Rollout Checklist

- [ ] Phase 7 runner passes locally: `npm run test:phase7:all`
- [ ] Phase 6 runner still passes: `npm run test:phase6:all`
- [ ] Phase 5 runner still passes: `npm run test:phase5:all`
- [ ] CI workflow created: `.github/workflows/phase7-ci.yml`
- [ ] CI passes on main branch
- [ ] Code reviewed by team
- [ ] Merge feature/phase6-runner-stability to main
- [ ] Tag release: `v0.7.0-idempotent-webhooks`
- [ ] Deploy to Firebase Cloud Functions (production)
- [ ] Monitor Stripe webhook processing in Cloud Logs for 24 hours
- [ ] Document any production incidents in PRODUCTION_INCIDENTS.md

---

## Quick Reference: Common Commands

```bash
# Start emulators locally
firebase emulators:start --only functions,firestore

# Run Phase 7 tests
cd functions && npm run test:phase7:all

# Run all test phases
cd functions && npm run test:all

# Check Node syntax
node --check functions/index.js

# Clear emulator data and restart
rm -rf ~/.cache/firebase/emulators
firebase emulators:start --only functions,firestore
```

---

## Appendix: FieldValue Safe Access Pattern

Throughout the codebase, we use a safe fallback for `admin.firestore.FieldValue.serverTimestamp()`:

```javascript
const ts = admin.firestore && admin.firestore.FieldValue 
  ? admin.firestore.FieldValue.serverTimestamp() 
  : new Date();
```

**Why**: In the emulator, `admin.firestore` or `FieldValue` may be undefined. The fallback uses `new Date()` instead, which works consistently.

---

## Next Steps (Phase 8+)

1. **Phase 8**: Implement charge.refunded webhook for order refunds
2. **Phase 9**: Wire up real notifications (FCM, email)
3. **Phase 10**: Production deployment and monitoring
4. **Phase 11**: A/B testing and performance optimization

---

**Last Updated**: Phase 7 Implementation Complete  
**Status**: Ready for Production  
**Locked**: Yes (idempotent webhook handling complete)
