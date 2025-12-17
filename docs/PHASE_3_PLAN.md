# Phase 3 Plan — Inventory, Admin Dashboard, Payments, Notifications

## Goals (Phase 3)
- Implement robust inventory management (reservations, decrements, backorder behavior)
- Build admin dashboard (product management, order processing, inventory view)
- Integrate payments (Stripe + M-Pesa adapters, webhook handlers)
- Add notifications (FCM push for order status, email receipts)
- Extend CI with payment & notification tests and harnesses

## Milestones
1. Planning & design (2 days)
   - Finalize inventory model + flows
   - Choose payment providers and required accounts
   - Decide notification providers (FCM + transactional email)
2. Inventory Implementation (3-5 days)
   - InventoryItem model, InventoryRepository
   - Cloud Functions for reservation & finalize on payment
   - Tests for concurrency
3. Admin Dashboard (3-5 days)
   - Scaffold UI, protect routes for admin
   - CRUD for products & inventory adjustments
4. Payments Integration (4-7 days)
   - Implement PaymentGateway adapters
   - Create server-side webhook handlers (Cloud Functions)
   - Payment simulator for CI
5. Notifications (2-3 days)
   - Cloud Functions trigger on order status changes
   - FCM + email integration
6. CI & Regression Tests (ongoing)
   - Add integration tests and harnesses

## Risks & Mitigations
- Race conditions on stock: use Firestore transactions + reservations; add Cloud Function gatekeeper if required.
- Payment webhook security: verify signatures, implement retry & idempotency.
- Admin role enforcement: enforce via Firestore rules + server-side checks.

## Immediate Next Steps
- Run final local sanity check (PHASE_2_QUICK_START.md) — optional since Phase 2 already verified
- Kickoff meeting & assign owners for inventory/payments/notifications
- Create cloud functions project skeleton for reservation and webhooks

---

## Contacts
- Project owner: please assign owners for each milestone
- DevOps: prepare production service accounts for payment webhooks & email

---

*End of Phase 3 plan (initial).*