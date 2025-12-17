// Payments simulator
// Implements a PaymentGateway interface and a StripeMock adapter (simulated)
// Creates orders and simulates successful and failed payments, updating order status accordingly.

const admin = require('firebase-admin');

process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-project' });
const db = admin.firestore();

function log(...args) { console.log('[payments-sim]', ...args); }

class PaymentGateway {
  // Simulate a charge: returns { success: boolean, id?: string }
  async charge(amountCents, metadata) { throw new Error('Not implemented'); }
}

class StripeMock extends PaymentGateway {
  constructor(shouldSucceed = true) {
    super();
    this.shouldSucceed = shouldSucceed;
  }

  async charge(amountCents, metadata) {
    // Simulate latency
    await new Promise((r) => setTimeout(r, 100));
    if (this.shouldSucceed) return { success: true, id: `ch_mock_${Date.now()}` };
    return { success: false, error: 'card_declined' };
  }
}

async function createOrder(totalPrice) {
  const docRef = await db.collection('orders').add({
    userId: 'sim-user',
    items: [],
    totalPrice,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return docRef.id;
}

async function updateOrderStatus(orderId, status) {
  await db.collection('orders').doc(orderId).update({ status, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
}

async function run() {
  try {
    // Create two orders: one will succeed, one will fail
    const orderSuccess = await createOrder(19.99);
    const orderFail = await createOrder(9.99);
    log('Created orders', orderSuccess, orderFail);

    // Simulate successful payment
    const gatewaySuccess = new StripeMock(true);
    const res1 = await gatewaySuccess.charge(1999, { orderId: orderSuccess });
    if (res1.success) {
      await updateOrderStatus(orderSuccess, 'confirmed');
      log('Order', orderSuccess, 'payment succeeded -> confirmed');
    } else {
      await updateOrderStatus(orderSuccess, 'payment_failed');
      throw new Error('Unexpected payment failure for success case');
    }

    // Simulate failed payment
    const gatewayFail = new StripeMock(false);
    const res2 = await gatewayFail.charge(999, { orderId: orderFail });
    if (!res2.success) {
      await updateOrderStatus(orderFail, 'cancelled');
      log('Order', orderFail, 'payment failed -> cancelled');
    } else {
      throw new Error('Unexpected payment success for failure case');
    }

    // Validate statuses
    const s1 = (await db.collection('orders').doc(orderSuccess).get()).data();
    const s2 = (await db.collection('orders').doc(orderFail).get()).data();

    if (s1.status !== 'confirmed') throw new Error(`order ${orderSuccess} status != confirmed`);
    if (s2.status !== 'cancelled') throw new Error(`order ${orderFail} status != cancelled`);

    console.log('\n✅ Payments simulator: PASS');
    process.exit(0);
  } catch (e) {
    console.error('\n❌ Payments simulator: FAIL');
    console.error(e);
    process.exit(1);
  }
}

if (require.main === module) run();
