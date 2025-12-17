/**
 * Simple integration test for the inventory reservation function.
 *
 * Requirements:
 * - Firebase emulators (functions + firestore) must be running locally.
 * - Set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
 *
 * This script:
 *  - Creates an inventory document for product 'TEST-PROD' with stock 5
 *  - Creates an order document with items [{productId: 'TEST-PROD', quantity: 3}]
 *  - Polls the order document until status becomes 'reserved' (success) or 'failed' (failure)
 *  - Verifies that inventory.reserved increased by 3 on success
 */

const admin = require('firebase-admin');

// Ensure we are pointing at the local emulator when running tests
// Example: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node test/reservation_test.js

async function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function main() {
  try {
    // Use default credentials; emulator doesn't need credentials
    admin.initializeApp();
  } catch (e) {
    // already initialized
  }

  const firestore = admin.firestore();

  const productId = 'TEST-PROD';
  const inventoryRef = firestore.collection('inventory').doc(productId);
  const orderRef = firestore.collection('orders').doc();

  console.log('Creating inventory doc', productId);
  await inventoryRef.set({ productId, stock: 5, reserved: 0 });

  console.log('Creating order doc', orderRef.id);
  const order = {
    userId: 'test-user-1',
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    items: [ { productId, productName: 'Test Product', quantity: 3, price: 100 } ],
    totalPrice: 300
  };

  await orderRef.set(order);

  console.log('Waiting for reservation function to process the order...');

  const timeoutMs = 30000; // 30s (longer for emulator)
  const start = Date.now();
  let finalStatus = null;
  let polls = 0;
  while ((Date.now() - start) < timeoutMs) {
    const snap = await orderRef.get();
    const data = snap.exists ? snap.data() : null;
    polls++;
    if (polls % 4 === 1) {
      console.log(`Poll ${polls}: status=${data?.status || 'unknown'}`);
    }
    if (data && data.status) {
      finalStatus = data.status;
      if (finalStatus === 'reserved' || finalStatus === 'failed') {
        console.log(`Status changed to: ${finalStatus}`);
        break;
      }
    }
    await sleep(1000); // increased to 1s
  }

  if (!finalStatus) {
    console.error('Timeout waiting for order status. Test failed.');
    process.exit(2);
  }

  console.log('Order final status:', finalStatus);

  if (finalStatus === 'reserved') {
    const invSnap = await inventoryRef.get();
    const inv = invSnap.exists ? invSnap.data() : {};
    const reserved = Number(inv.reserved || 0);
    if (reserved >= 3) {
      console.log('Reservation succeeded: reserved=', reserved);
      process.exit(0);
    } else {
      console.error('Reservation did not update inventory.reserved as expected:', inv);
      process.exit(3);
    }
  } else {
    console.error('Order failed reservation:', (await orderRef.get()).data());
    process.exit(4);
  }
}

main().catch((err) => { console.error(err); process.exit(1); });
