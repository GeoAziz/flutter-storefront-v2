const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize admin SDK. In emulator or production this will pick up the
// appropriate credentials / environment.
try {
  // Explicitly set projectId to ensure correct DB context in emulator and production
  admin.initializeApp({
    projectId: 'demo-project'
  });
} catch (e) {
  // ignore if already initialized
}

const firestore = admin.firestore();

const { getProviderFromEnv } = require('./lib/paymentProvider');
const paymentProvider = getProviderFromEnv();

/**
 * Simple fixed-window rate limiter stored in Firestore.
 *
 * Callable signature (https.onCall)
 * data: { action: string, limit?: number, windowSec?: number, writePath?: string, writeData?: object }
 * context.auth: user must be authenticated; uid is used for per-user limits.
 *
 * Behavior:
 *  - Uses a document per user+action in `rate_limits` collection.
 *  - The document stores { count: number, start: number } where start is epoch ms
 *  - If within window and count >= limit -> rejects with resource-exhausted
 *  - Otherwise increments count and optionally performs a single write
 *
 * Notes/limits:
 *  - Fixed window is simple and cheap. For high accuracy consider sliding window
 *    or leaky bucket variants or Redis for high throughput.
 *  - Keep function logic lightweight to minimize compute and invocation cost.
 */
exports.rateLimitedWrite = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const uid = context.auth.uid;
  const action = (data && data.action) ? String(data.action) : 'generic';
  const limit = (data && Number.isFinite(data.limit)) ? Number(data.limit) : 20; // default 20
  const windowSec = (data && Number.isFinite(data.windowSec)) ? Number(data.windowSec) : 60; // default 60s

  const now = Date.now();
  const docId = `${uid}__${action}`;
  const docRef = firestore.collection('rate_limits').doc(docId);

  const result = await firestore.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    let count = 0;
    let start = now;
    if (snap.exists) {
      const d = snap.data() || {};
      const startTs = d.start || 0;
      if ((now - startTs) <= (windowSec * 1000)) {
        count = d.count || 0;
        start = startTs;
      } else {
        // window expired -> reset
        count = 0;
        start = now;
      }
    }

    if ((count + 1) > limit) {
      // Exceeded: return retryAfter in ms
      return { allowed: false, retryAfter: (start + (windowSec * 1000) - now) };
    }

    tx.set(docRef, { count: count + 1, start: start }, { merge: true });
    return { allowed: true };
  });

  if (!result.allowed) {
    throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded', { retryAfterMs: result.retryAfter });
  }

  // Optionally perform a write operation provided by the caller.
  if (data && data.writePath && data.writeData) {
    const writePath = String(data.writePath);
    const writeData = data.writeData;
    await firestore.doc(writePath).set(writeData, { merge: true });
  }

  return { success: true };
});


/**
 * Batched write helper to reduce number of client->function invocations.
 * Accepts an array of operations (up to 500 per batch) and writes them in chunks.
 *
 * Callable signature:
 * data: { ops: [{ op: 'set'|'update'|'delete', path: string, data?: object }], merge?: boolean }
 *
 * This function performs as few Firestore batch commits as necessary. Keep op
 * count reasonably small to avoid heavy compute per invocation.
 */
exports.batchWrite = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const ops = Array.isArray(data && data.ops) ? data.ops : [];
  if (ops.length === 0) {
    return { applied: 0 };
  }

  const CHUNK = 450; // keep below 500
  let applied = 0;

  for (let i = 0; i < ops.length; i += CHUNK) {
    const chunk = ops.slice(i, i + CHUNK);
    const batch = firestore.batch();
    for (const op of chunk) {
      if (!op.path) continue;
      const ref = firestore.doc(String(op.path));
      const verb = String(op.op || 'set').toLowerCase();
      if (verb === 'delete') {
        batch.delete(ref);
      } else if (verb === 'update') {
        batch.update(ref, op.data || {});
      } else {
        // set by default
        batch.set(ref, op.data || {}, { merge: !!data.merge });
      }
    }
    await batch.commit();
    applied += chunk.length;
  }

  return { applied };
});


/**
 * Inventory reservation logic (shared by trigger + callable).
 * Attempts to reserve stock for all items in an order atomically.
 * Returns { success: boolean, message?: string }
 */
async function performInventoryReservation(orderId) {
  const orderRef = firestore.collection('orders').doc(orderId);
  const snap = await orderRef.get();
  
  if (!snap.exists) {
    throw new Error('order_not_found');
  }

  const order = snap.data() || {};
  const items = Array.isArray(order.items) ? order.items : [];

  if (items.length === 0) {
    // nothing to reserve
    const timestamp = admin && admin.firestore && admin.firestore.FieldValue ? admin.firestore.FieldValue.serverTimestamp() : new Date();
    await orderRef.update({ status: 'reserved', reservedAt: timestamp }).catch(() => {});
    return { success: true, message: 'no_items' };
  }

  const productIds = Array.from(new Set(items.map((it) => it.productId)));
  const invRefs = productIds.map((pid) => firestore.collection('inventory').doc(pid));

  try {
    await firestore.runTransaction(async (tx) => {
      // Gather inventory snapshots
      const invSnaps = await Promise.all(invRefs.map((r) => tx.get(r)));

      // Map productId -> snapshot
      const invMap = {};
      for (let i = 0; i < invRefs.length; i++) {
        const pid = productIds[i];
        const s = invSnaps[i];
        if (!s.exists) {
          throw new Error(`inventory_not_found:${pid}`);
        }
        invMap[pid] = s.data() || {};
      }

      // Verify availability
      for (const it of items) {
        const pid = it.productId;
        const qty = Number(it.quantity || 0);
        const inv = invMap[pid] || {};
        const stock = Number(inv.stock || 0);
        const reserved = Number(inv.reserved || 0);
        if (stock - reserved < qty) {
          throw new Error(`insufficient_stock:${pid}`);
        }
      }

      // All good -> perform reserved increments
      for (const it of items) {
        const pid = it.productId;
        const qty = Number(it.quantity || 0);
        const ref = firestore.collection('inventory').doc(pid);
        const currentReserved = Number(invMap[pid].reserved || 0);
        tx.update(ref, { reserved: currentReserved + qty });
      }
    });

    // Mark order as reserved
    const timestamp = admin.firestore.FieldValue ? admin.firestore.FieldValue.serverTimestamp() : new Date();
    await orderRef.update({ status: 'reserved', reservedAt: timestamp });
    return { success: true, message: 'reserved' };
  } catch (err) {
    // Mark order failed with reason (keep message small)
    const reason = (err && err.message) ? String(err.message).substring(0, 200) : 'reservation_error';
    await orderRef.update({ status: 'failed', failureReason: reason }).catch(() => {});
    return { success: false, message: reason };
  }
}

/**
 * Finalize inventory for an order: decrement stock and clear reserved.
 * Must be performed inside a transaction to ensure consistency.
 */
async function performInventoryFinalize(orderId) {
  const orderRef = firestore.collection('orders').doc(orderId);
  const snap = await orderRef.get();
  if (!snap.exists) {
    throw new Error('order_not_found');
  }

  const order = snap.data() || {};
  const items = Array.isArray(order.items) ? order.items : [];

  if (items.length === 0) {
    const ts = admin && admin.firestore && admin.firestore.FieldValue ? admin.firestore.FieldValue.serverTimestamp() : new Date();
    await orderRef.update({ status: 'finalized', finalizedAt: ts }).catch(() => {});
    return { success: true, message: 'no_items' };
  }

  try {
    await firestore.runTransaction(async (tx) => {
      // Read current inventory docs
      const invRefs = items.map((it) => firestore.collection('inventory').doc(it.productId));
      const invSnaps = await Promise.all(invRefs.map((r) => tx.get(r)));

      // Verify reserved amounts and apply final decrease
      for (let i = 0; i < items.length; i++) {
        const it = items[i];
        const snapInv = invSnaps[i];
        if (!snapInv.exists) throw new Error(`inventory_not_found:${it.productId}`);
        const inv = snapInv.data() || {};
        const reserved = Number(inv.reserved || 0);
        const stock = Number(inv.stock || 0);
        const qty = Number(it.quantity || 0);
        if (reserved < qty) throw new Error(`insufficient_reserved:${it.productId}`);
        // Apply updates: stock -= qty, reserved -= qty
        tx.update(invRefs[i], { stock: stock - qty, reserved: reserved - qty });
      }
    });

    // Mark order finalized
    const ts = admin && admin.firestore && admin.firestore.FieldValue ? admin.firestore.FieldValue.serverTimestamp() : new Date();
    await orderRef.update({ status: 'finalized', finalizedAt: ts });
    return { success: true, message: 'finalized' };
  } catch (err) {
    const reason = (err && err.message) ? String(err.message).substring(0, 200) : 'finalize_error';
    await orderRef.update({ status: 'failed', failureReason: reason }).catch(() => {});
    return { success: false, message: reason };
  }
}

/**
 * Append an entry to auditLog (functions are authoritative writers)
 */
async function writeAuditLog(entry) {
  const timestamp = admin.firestore.FieldValue ? admin.firestore.FieldValue.serverTimestamp() : new Date();
  const payload = Object.assign({}, entry, { createdAt: timestamp });
  await firestore.collection('auditLog').add(payload);
}

/**
 * Notification stub - functions write notifications for clients. In Spark
 * plan / emulator we simply write to `notifications/{userId}/messages`.
 */
async function writeNotification(userId, payload) {
  try {
    const ref = firestore.collection('notifications').doc(String(userId)).collection('messages').doc();
    const data = Object.assign({}, payload, { createdAt: admin.firestore.FieldValue ? admin.firestore.FieldValue.serverTimestamp() : new Date() });
    await ref.set(data);
  } catch (e) {
    console.error('writeNotification error', e && e.message ? e.message : e);
  }
}

/**
 * Generic processor for functionRequests docs. Clients may create a
 * lightweight request document in `functionRequests` collection with the
 * following shape:
 * { type: 'reserveInventory'|'finalizeInventory'|'orderTransition', orderId, payload, userId, createdAt }
 * The function performs the authoritative action and then removes the request.
 */
exports.processFunctionRequest = functions.firestore.document('functionRequests/{reqId}').onCreate(async (snap, ctx) => {
  const req = snap.data() || {};
  const reqId = ctx.params.reqId;
  try {
    if (!req || !req.type) {
      await firestore.collection('functionRequests').doc(reqId).delete().catch(() => {});
      return null;
    }

    const type = String(req.type);
    if (type === 'reserveInventory') {
      const orderId = String(req.orderId);
      const res = await performInventoryReservation(orderId);
      await writeAuditLog({ kind: 'reserveInventory', orderId, result: res });
    } else if (type === 'finalizeInventory') {
      const orderId = String(req.orderId);
      // Run payment provider (mock or Stripe if configured)
      const paymentResult = await paymentProvider.charge(req.payload || {});
      // If payment failed, write audit and mark order failed
      if (!paymentResult || !paymentResult.success) {
        await writeAuditLog({ kind: 'finalizeInventory', orderId, paymentResult, result: { success: false } });
      } else {
        const finalizeRes = await performInventoryFinalize(orderId);
        await writeAuditLog({ kind: 'finalizeInventory', orderId, paymentResult, result: finalizeRes });
        // Send notification stub
        await writeNotification(req.userId || req.userID || 'system', { type: 'order_finalized', orderId, paymentId: paymentResult.id });
      }
    } else if (type === 'orderTransition') {
      // Example: admin requested state transition (functions only)
      const orderId = String(req.orderId);
      const newStatus = String(req.payload && req.payload.status || 'unknown');
      await firestore.collection('orders').doc(orderId).update({ status: newStatus });
      await writeAuditLog({ kind: 'orderTransition', orderId, to: newStatus });
    }
  } catch (e) {
    console.error('processFunctionRequest error', e && e.stack ? e.stack : e);
    // keep the request for inspection by writing an error field
    const ts = admin && admin.firestore && admin.firestore.FieldValue ? admin.firestore.FieldValue.serverTimestamp() : new Date();
    await firestore.collection('functionRequests').doc(reqId).set({ processedAt: ts, error: String(e && e.message || e) }, { merge: true }).catch(() => {});
    return null;
  }

  // Remove the processed request doc (cleanup)
  await firestore.collection('functionRequests').doc(reqId).delete().catch(() => {});
  return null;
});


/**
 * Stripe webhook handler (HTTP). For emulator testing we accept a simplified
 * event payload that matches Stripe's event shape: { type, data: { object: { metadata: { orderId } } } }
 * In production, validate signatures using stripe.webhooks.constructEvent.
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  try {
    console.log('🔍 [Webhook] Received request, method:', req.method, 'body:', JSON.stringify(req.body));
    const evt = req.body || {};
    const type = String(evt.type || '');
    const obj = (evt.data && evt.data.object) ? evt.data.object : {};
    const orderId = (obj.metadata && obj.metadata.orderId) ? String(obj.metadata.orderId) : (req.query.orderId || null);

    console.log('🔍 [Webhook] Parsed type:', type, 'orderId:', orderId);
    if (!orderId) {
      res.status(400).send('missing orderId');
      return;
    }

    if (type === 'payment_intent.succeeded' || type === 'charge.succeeded') {
      // Payment succeeded -> finalize order
      console.log('🔍 [Webhook] Payment succeeded for', orderId, 'calling finalize');
      await performInventoryFinalize(orderId);
      console.log('🔍 [Webhook] Finalize completed');
      await writeAuditLog({ kind: 'stripe_webhook', event: type, orderId });
      await writeNotification('system', { type: 'payment_succeeded', orderId });
      res.status(200).send('ok');
      return;
    }

    // For other events just ack
    res.status(200).send('ignored');
  } catch (e) {
    console.error('stripeWebhook error', e && e.stack ? e.stack : e);
    res.status(500).send('error');
  }
});

/**
 * Firestore trigger (may not fire in emulator; we have callable as fallback).
 */
exports.reserveInventoryOnOrderCreate = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    await performInventoryReservation(context.params.orderId);
    return null;
  });

/**
 * HTTP callable version (works better in emulator + production backup).
 * Call from client or server-side after order creation.
 * In production, requires authentication. In emulator, auth is optional for testing.
 */
exports.reserveInventory = functions.https.onCall(async (data, context) => {
  // In production, require auth. In emulator (context.auth is null), allow for testing.
  const isProduction = process.env.NODE_ENV === 'production';
  if (isProduction && (!context.auth || !context.auth.uid)) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const orderId = (data && data.orderId) ? String(data.orderId) : null;
  if (!orderId) {
    throw new functions.https.HttpsError('invalid-argument', 'orderId required');
  }

  const result = await performInventoryReservation(orderId);
  if (!result.success) {
    throw new functions.https.HttpsError('failed-precondition', result.message);
  }
  return result;
});
