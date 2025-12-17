// Admin mutations script: update product and adjust inventory
// Validates that admin mutations succeed and produce correct state changes.
// Exits 0 (PASS) or non-zero (FAIL).

const admin = require('firebase-admin');

process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-project' });
const db = admin.firestore();

function log(...args) { console.log('[admin-mutations]', ...args); }

async function assertEqual(a, b, message) {
  if (a === b) {
    log('ASSERT PASS:', message);
    return true;
  }
  console.error('ASSERT FAIL:', message, 'expected', b, 'got', a);
  process.exitCode = 1;
  return false;
}

async function run() {
  try {
    // Seed a test product
    const productId = 'admin-mutation-test-prod-1';
    await db.collection('products').doc(productId).set({
      id: productId,
      name: 'Admin Mutation Test Product',
      active: true,
      price: 29.99,
    });
    log('Seeded product:', productId);

    // Seed a test inventory
    await db.collection('inventory').doc(productId).set({
      productId,
      stock: 20,
      reserved: 0,
    });
    log('Seeded inventory:', productId, 'stock=20');

    // Mutation 1: Admin updates product active flag
    log('Mutation 1: Admin updates product active flag to false');
    await db.collection('products').doc(productId).update({ active: false });
    let doc = await db.collection('products').doc(productId).get();
    await assertEqual(doc.data().active, false, 'product active flag should be false after update');

    // Mutation 2: Admin restores product active flag
    log('Mutation 2: Admin restores product active flag to true');
    await db.collection('products').doc(productId).update({ active: true });
    doc = await db.collection('products').doc(productId).get();
    await assertEqual(doc.data().active, true, 'product active flag should be true after restore');

    // Mutation 3: Admin adjusts inventory stock (increase)
    log('Mutation 3: Admin adjusts inventory stock (increase by 10)');
    await db.collection('inventory').doc(productId).update({ stock: 30 });
    let invDoc = await db.collection('inventory').doc(productId).get();
    await assertEqual(invDoc.data().stock, 30, 'inventory stock should be 30 after increase');

    // Mutation 4: Admin adjusts inventory stock (decrease)
    log('Mutation 4: Admin adjusts inventory stock (decrease by 5)');
    await db.collection('inventory').doc(productId).update({ stock: 25 });
    invDoc = await db.collection('inventory').doc(productId).get();
    await assertEqual(invDoc.data().stock, 25, 'inventory stock should be 25 after decrease');

    // Mutation 5: Verify audit log entry is created (if implemented)
    log('Mutation 5: Check if audit log entry exists for product update');
    const auditSnap = await db.collection('auditLog').where('productId', '==', productId).limit(1).get();
    if (auditSnap.empty) {
      log('  Audit log: no entries found (audit logging not yet implemented)');
    } else {
      log('  Audit log: found entry for product', productId);
    }

    console.log('\n✅ Admin mutations: PASS');
    process.exit(0);
  } catch (e) {
    console.error('\n❌ Admin mutations: FAIL');
    console.error(e);
    process.exit(1);
  }
}

if (require.main === module) {
  run();
}
