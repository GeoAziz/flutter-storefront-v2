// Phase 6 runner: validate payment webhooks + finalize flows
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

const admin = require('firebase-admin');
const fetch = require('node-fetch');

try { admin.initializeApp({ projectId: 'demo-project' }); } catch (e) {}
const db = admin.firestore();
const log = (s, ...r) => console.log('[phase6]', s, ...r);

async function run() {
  try {
    const runId = Math.random().toString(36).substring(7);
    log('Seeding product + inventory (runId: ' + runId + ')');
    const pid = 'phase6-prod-' + runId;
    await db.collection('products').doc(pid).set({ id: pid, name: 'Phase6 Product', active: true });
    await db.collection('inventory').doc(pid).set({ productId: pid, stock: 50, reserved: 0 });

    // Create an order (this will trigger reserveInventoryOnOrderCreate automatically)
    const orderRef = db.collection('orders').doc();
    const orderId = orderRef.id;
    await orderRef.set({ userId: 'phase6-user', items: [{ productId: pid, quantity: 2 }], status: 'pending', createdAt: admin.firestore.FieldValue.serverTimestamp() });
    log('Created order', orderId);

    // Wait for reservation to be applied (poll up to ~15s)
    // The trigger reserveInventoryOnOrderCreate will update status to 'reserved' automatically
    let reserved = false;
    for (let i = 0; i < 30; i++) {
      const orderSnap = await db.collection('orders').doc(orderId).get();
      if (orderSnap.exists && orderSnap.data().status === 'reserved') {
        reserved = true;
        break;
      }
      await sleep(500);
    }
    if (!reserved) {
      console.error('❌ reserve did not complete (timed out)');
      process.exit(1);
    }
    log('Order reserved');

    // Simulate payment via payment adapter: in emulator we don't hit Stripe.
    // Instead, we simulate a Stripe webhook by POSTing to the functions emulator.
    const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
    const url = `http://${functionsHost}/demo-project/us-central1/stripeWebhook`;
    const payload = { type: 'payment_intent.succeeded', data: { object: { metadata: { orderId } } } };
    log('Posting simulated Stripe webhook to', url);
    const res = await fetch(url, { method: 'POST', body: JSON.stringify(payload), headers: { 'Content-Type': 'application/json' } });
    if (!res.ok) {
      console.error('❌ webhook POST failed', res.status, await res.text());
      process.exit(1);
    }
    log('Webhook posted');

    // Wait for finalize (poll up to ~15s)
    let finalizedOk = false;
    for (let i = 0; i < 30; i++) {
      const snap = await db.collection('orders').doc(orderId).get();
      if (snap.exists && snap.data().status === 'finalized') {
        finalizedOk = true;
        break;
      }
      await sleep(500);
    }
    if (!finalizedOk) {
      const snap = await db.collection('orders').doc(orderId).get();
      console.error('❌ finalize did not complete (timed out)', snap.exists ? snap.data() : null);
      process.exit(1);
    }
    log('Order finalized');

    // Check inventory
    const inv = await db.collection('inventory').doc(pid).get();
    const invData = inv.data();
    if ((invData.stock || 0) !== 48 || (invData.reserved || 0) !== 0) {
      console.error('❌ inventory mismatch', invData);
      process.exit(1);
    }
    log('Inventory correct');

    // Check audit log
    const auditQ = await db.collection('auditLog').where('orderId', '==', orderId).get();
    if (auditQ.empty) {
      console.error('❌ audit logs missing');
      process.exit(1);
    }
    log('Audit entries found:', auditQ.size);

    // Check notification written
    const notifQ = await db.collection('notifications').doc('system').collection('messages').where('orderId', '==', orderId).get();
    log('Notifications for system:', notifQ.size);

    console.log('\n✅ Phase 6 runner: ALL TESTS PASSED');
    process.exit(0);
  } catch (e) {
    console.error('❌ Phase 6 runner: FAIL', e && e.stack ? e.stack : e);
    process.exit(1);
  }
}

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

if (require.main === module) run();
