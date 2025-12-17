/**
 * Debug-focused integration test for inventory reservation callable function
 * Tests: order creation → function invocation → reservation validation
 */
const admin = require('firebase-admin');
const fetch = require('node-fetch');

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function main() {
  try {
    admin.initializeApp({
      projectId: 'demo-project'
    });
  } catch (e) {
    // ignore if already initialized
  }

  const firestore = admin.firestore();
  const projectId = 'demo-project';
  const functionUrl = `http://127.0.0.1:5001/${projectId}/us-central1/reserveInventory`;

  // Step 1: Create inventory
  console.log('\n📍 STEP 1: Create inventory document');
  const inventoryRef = firestore.collection('inventory').doc('TEST-PROD-999');
  await inventoryRef.set({ productId: 'TEST-PROD-999', stock: 10, reserved: 0 });
  console.log('   ✓ Inventory created');

  // Step 2: Verify inventory exists
  console.log('\n📍 STEP 2: Verify inventory in emulator');
  let invSnap = await inventoryRef.get();
  if (!invSnap.exists) {
    console.error('   ❌ Inventory doc not found after creation!');
    process.exit(1);
  }
  console.log('   ✓ Inventory verified:', invSnap.data());

  // Step 3: Create order
  console.log('\n📍 STEP 3: Create order document');
  const orderRef = firestore.collection('orders').doc();
  const order = {
    userId: 'test-user-' + Date.now(),
    status: 'pending',
    items: [
      {
        productId: 'TEST-PROD-999',
        productName: 'Test Product',
        quantity: 2,
        price: 100
      }
    ],
    totalPrice: 200,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };
  await orderRef.set(order);
  console.log('   ✓ Order created:', orderRef.id);

  // Step 4: Verify order exists in emulator
  console.log('\n📍 STEP 4: Verify order in emulator (client-side read)');
  let orderSnap = await orderRef.get();
  if (!orderSnap.exists) {
    console.error('   ❌ Order doc not found after creation!');
    process.exit(1);
  }
  console.log('   ✓ Order verified. Status:', orderSnap.data().status);
  console.log('   ✓ Order items:', orderSnap.data().items);

  // Step 5: Wait a bit
  console.log('\n📍 STEP 5: Waiting 500ms for data to fully persist...');
  await sleep(500);

  // Step 6: Call the HTTP callable function
  console.log('\n📍 STEP 6: Call HTTP callable function');
  console.log('   URL:', functionUrl);
  console.log('   Data:', { orderId: orderRef.id });
  
  let functionResponse;
  try {
    const httpResponse = await fetch(functionUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ data: { orderId: orderRef.id } })
    });
    functionResponse = await httpResponse.text();
    console.log('   HTTP Status:', httpResponse.status);
    console.log('   Response:', functionResponse);

    if (httpResponse.status >= 400) {
      console.error('   ❌ Function returned error!');
      process.exit(1);
    }
  } catch (err) {
    console.error('   ❌ Error calling function:', err.message);
    process.exit(1);
  }

  // Step 7: Wait for async operations
  console.log('\n📍 STEP 7: Waiting 2000ms for function to complete...');
  await sleep(2000);

  // Step 8: Verify order status changed to 'reserved'
  console.log('\n📍 STEP 8: Verify order status changed to "reserved"');
  const finalOrderSnap = await orderRef.get();
  const finalOrder = finalOrderSnap.data();
  console.log('   Order status:', finalOrder.status);
  
  if (finalOrder.status !== 'reserved') {
    console.error('   ❌ FAIL: Order status is not "reserved", it is:', finalOrder.status);
    if (finalOrder.failureReason) {
      console.error('   Failure reason:', finalOrder.failureReason);
    }
    process.exit(1);
  }
  console.log('   ✓ Order status is "reserved"');

  // Step 9: Verify inventory.reserved increased
  console.log('\n📍 STEP 9: Verify inventory.reserved increased');
  const finalInvSnap = await inventoryRef.get();
  const finalInv = finalInvSnap.data();
  console.log('   Inventory:', finalInv);
  
  if ((finalInv.reserved || 0) < 2) {
    console.error('   ❌ FAIL: inventory.reserved is', finalInv.reserved, 'but should be >= 2');
    process.exit(1);
  }
  console.log('   ✓ Inventory.reserved is', finalInv.reserved, '(expected 2)');

  console.log('\n✅ SUCCESS: End-to-end inventory reservation test passed!');
  process.exit(0);
}

main().catch(err => {
  console.error('Unhandled error:', err);
  process.exit(2);
});
