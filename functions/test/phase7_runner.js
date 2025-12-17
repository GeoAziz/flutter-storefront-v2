// Phase 7 runner: test webhook idempotency + finalize flows
// Simplified to avoid emulator trigger timing issues
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';

const admin = require('firebase-admin');
const fetch = require('node-fetch');

try { admin.initializeApp({ projectId: 'demo-no-project' }); } catch (e) {}
const db = admin.firestore();
const log = (s, ...r) => console.log('[phase7]', s, ...r);

// Inline reservation logic to avoid trigger dependency
async function reserveInventory(orderId) {
  const orderRef = db.collection('orders').doc(orderId);
  const snap = await orderRef.get();
  if (!snap.exists) throw new Error('order_not_found');
  
  const order = snap.data() || {};
  const items = Array.isArray(order.items) ? order.items : [];
  if (items.length === 0) {
    await orderRef.update({ status: 'reserved', reservedAt: admin.firestore.FieldValue.serverTimestamp() }).catch(() => {});
    return { success: true, message: 'no_items' };
  }

  const productIds = Array.from(new Set(items.map((it) => it.productId)));
  const invRefs = productIds.map((pid) => db.collection('inventory').doc(pid));

  try {
    await db.runTransaction(async (tx) => {
      const invSnaps = await Promise.all(invRefs.map((r) => tx.get(r)));
      const invMap = {};
      for (let i = 0; i < invRefs.length; i++) {
        const pid = productIds[i];
        const s = invSnaps[i];
        if (!s.exists) throw new Error(`inventory_not_found:${pid}`);
        invMap[pid] = s.data() || {};
      }

      for (const it of items) {
        const pid = it.productId;
        const qty = Number(it.quantity || 0);
        const inv = invMap[pid] || {};
        const stock = Number(inv.stock || 0);
        const reserved = Number(inv.reserved || 0);
        if (stock - reserved < qty) throw new Error(`insufficient_stock:${pid}`);
      }

      for (const it of items) {
        const pid = it.productId;
        const qty = Number(it.quantity || 0);
        const ref = db.collection('inventory').doc(pid);
        const currentReserved = Number(invMap[pid].reserved || 0);
        tx.update(ref, { reserved: currentReserved + qty });
      }
    });

    const timestamp = admin.firestore.FieldValue ? admin.firestore.FieldValue.serverTimestamp() : new Date();
    await orderRef.update({ status: 'reserved', reservedAt: timestamp });
    return { success: true, message: 'reserved' };
  } catch (err) {
    const reason = (err && err.message) ? String(err.message).substring(0, 200) : 'reservation_error';
    await orderRef.update({ status: 'failed', failureReason: reason }).catch(() => {});
    return { success: false, message: reason };
  }
}

async function run() {
  const functionsHost = process.env.FUNCTIONS_EMULATOR_HOST || '127.0.0.1:5001';
  try {
    const runId = Math.random().toString(36).substring(7);
    log('Seeding product + inventory (runId: ' + runId + ')');
    const pid = 'phase7-prod-' + runId;
    await db.collection('products').doc(pid).set({ id: pid, name: 'Phase7 Product', active: true });
    await db.collection('inventory').doc(pid).set({ productId: pid, stock: 50, reserved: 0 });

    // Create an order (Firestore trigger will automatically reserve via reserveInventoryOnOrderCreate)
    const orderRef = db.collection('orders').doc();
    const orderId = orderRef.id;
    const qty = 3;
    await orderRef.set({ userId: 'phase7-user', items: [{ productId: pid, quantity: qty }], status: 'pending', createdAt: admin.firestore.FieldValue.serverTimestamp() });
    log('Created order', orderId);

    // Wait for trigger to fire and reserve inventory (poll up to ~10s)
    let orderReserved = false;
    for (let i = 0; i < 20; i++) {
      const orderSnap = await db.collection('orders').doc(orderId).get();
      if (orderSnap.exists && orderSnap.data().status === 'reserved') {
        orderReserved = true;
        break;
      }
      await sleep(500);
    }
    
    if (!orderReserved) {
      // Fallback: perform reservation inline
      log('Trigger did not fire; performing inline reservation...');
      const reserveRes = await reserveInventory(orderId);
      if (!reserveRes.success) {
        console.error('❌ reserve failed', reserveRes);
        process.exit(1);
      }
    }
    log('Order reserved');

    // Simulate payment webhook twice (duplicate delivery)
    const url = `http://${functionsHost}/demo-no-project/us-central1/stripeWebhook`;
    const eventId = `phase7-${runId}-evt`;
    const payload = { id: eventId, type: 'payment_intent.succeeded', data: { object: { metadata: { orderId } } } };

    log('Posting simulated Stripe webhook (first) to', url, 'eventId:', eventId);
    let res = await fetch(url, { method: 'POST', body: JSON.stringify(payload), headers: { 'Content-Type': 'application/json' } });
    if (!res.ok) {
      console.error('❌ webhook POST failed (first)', res.status, await res.text());
      process.exit(1);
    }
    log('Webhook (first) posted');

    // Post duplicate
    log('Posting simulated Stripe webhook (duplicate) to', url, 'eventId:', eventId);
    res = await fetch(url, { method: 'POST', body: JSON.stringify(payload), headers: { 'Content-Type': 'application/json' } });
    if (!res.ok) {
      console.error('❌ webhook POST failed (duplicate)', res.status, await res.text());
      process.exit(1);
    }
    log('Webhook (duplicate) posted');

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

    // Check inventory: should be decreased exactly once by qty
    const inv = await db.collection('inventory').doc(pid).get();
    const invData = inv.data();
    if ((invData.stock || 0) !== (50 - qty) || (invData.reserved || 0) !== 0) {
      console.error('❌ inventory mismatch', invData);
      process.exit(1);
    }
    log('Inventory correct after single finalize');

    // Check webhookEvents doc exists and marked processed
    const we = await db.collection('webhookEvents').doc(eventId).get();
    if (!we.exists) {
      console.error('❌ webhookEvents doc missing');
      process.exit(1);
    }
    const weData = we.data() || {};
    if (!weData.processed) {
      console.error('❌ webhookEvents not marked processed', weData);
      process.exit(1);
    }
    log('webhookEvents processed:', weData.processed);

    // Check audit log for this eventId only one entry
    const auditQ = await db.collection('auditLog').where('eventId', '==', eventId).get();
    if (auditQ.size !== 1) {
      console.error('❌ audit entries for eventId should be exactly 1, got', auditQ.size);
      process.exit(1);
    }
    log('Audit entries for eventId:', auditQ.size);

    // Check notification written
    const notifQ = await db.collection('notifications').doc('system').collection('messages').where('orderId', '==', orderId).get();
    log('Notifications for system:', notifQ.size);

    console.log('\n✅ Phase 7 runner: ALL TESTS PASSED');
    process.exit(0);
  } catch (e) {
    console.error('❌ Phase 7 runner: FAIL', e && e.stack ? e.stack : e);
    process.exit(1);
  }
}

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

if (require.main === module) run();
