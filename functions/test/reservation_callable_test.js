/**
 * Integration test for inventory reservation using the HTTP callable function.
 * This approach is more reliable in the emulator than Firestore triggers.
 *
 * Requirements:
 * - Firebase emulators (functions + firestore) must be running locally.
 * - Set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
 *
 * This script:
 *  - Creates an inventory document for product 'TEST-PROD' with stock 5
 *  - Creates an order document with items [{productId: 'TEST-PROD', quantity: 3}]
 *  - Calls the reserveInventory HTTP function with orderId
 *  - Verifies that order status becomes 'reserved' and inventory.reserved increases by 3
 */

const admin = require('firebase-admin');
const fetch = require('node-fetch');

async function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function main() {
  try {
    admin.initializeApp();
  } catch (e) {
    // already initialized
  }

  const firestore = admin.firestore();
  const projectId = 'demo-project';
  const functionUrl = `http://127.0.0.1:5001/${projectId}/us-central1/reserveInventory`;

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

  // Verify order was created
  const verifyOrderSnap = await orderRef.get();
  if (!verifyOrderSnap.exists) {
    console.error('❌ Order was not created!');
    process.exit(1);
  }
  console.log('✓ Order created successfully:', orderRef.id);

  // Wait a bit for Firestore to fully persist
  await sleep(500);

  console.log('Calling reserveInventory HTTP function for orderId:', orderRef.id);
  
  // Create a custom token for authentication (not needed in emulator, but we'll use null for simplicity)
  // In emulator, we skip auth check
  try {
    const response = await fetch(functionUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data: { orderId: orderRef.id } })
    });

    const responseBody = await response.text();
    console.log('Function response status:', response.status);
    console.log('Function response:', responseBody);

    if (response.status >= 400) {
      console.error('Function call failed. In emulator, this might be auth-related. Checking order status anyway...');
    }
  } catch (err) {
    console.error('Error calling function:', err.message);
  }

  // Small delay to allow function to complete
  await sleep(2000);

  // Check final order status
  const finalOrderSnap = await orderRef.get();
  const finalOrder = finalOrderSnap.data();
  console.log('Order after function call:', finalOrder);

  if (finalOrder && finalOrder.status === 'reserved') {
    const invSnap = await inventoryRef.get();
    const inv = invSnap.exists ? invSnap.data() : {};
    const reserved = Number(inv.reserved || 0);
    console.log('Inventory after function call:', inv);
    
    if (reserved >= 3) {
      console.log('✅ SUCCESS: Reservation succeeded. reserved=', reserved);
      process.exit(0);
    } else {
      console.error('❌ FAIL: Reservation did not update inventory.reserved as expected:', inv);
      process.exit(3);
    }
  } else {
    console.error('❌ FAIL: Order status not reserved:', finalOrder);
    process.exit(4);
  }
}

main().catch((err) => { 
  console.error('Test error:', err); 
  process.exit(1); 
});
