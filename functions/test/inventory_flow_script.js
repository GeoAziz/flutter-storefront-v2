// Inventory flow script
// Seeds inventory, runs reserve -> finalize -> release scenarios and reports PASS/FAIL

const admin = require('firebase-admin');

const FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;

// Initialize admin SDK for emulator
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-project' });
const db = admin.firestore();

function log(...args) { console.log('[inventory-flow]', ...args); }

async function seedInventory(productId, stock) {
  log('Seeding inventory', productId, 'stock=', stock);
  await db.collection('inventory').doc(productId).set({
    productId,
    stock,
    reserved: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function getInventory(productId) {
  const doc = await db.collection('inventory').doc(productId).get();
  return doc.exists ? doc.data() : null;
}

async function reserve(productId, qty) {
  const docRef = db.collection('inventory').doc(productId);
  return db.runTransaction(async (tx) => {
    const doc = await tx.get(docRef);
    if (!doc.exists) return false;
    const data = doc.data();
    const stock = (data.stock || 0);
    const reserved = (data.reserved || 0);
    if ((stock - reserved) < qty) return false;
    tx.update(docRef, { reserved: reserved + qty, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    return true;
  });
}

async function finalize(productId, qty) {
  const docRef = db.collection('inventory').doc(productId);
  return db.runTransaction(async (tx) => {
    const doc = await tx.get(docRef);
    if (!doc.exists) return false;
    const data = doc.data();
    const stock = (data.stock || 0);
    const reserved = (data.reserved || 0);
    if (reserved < qty || stock < qty) return false;
    tx.update(docRef, { stock: stock - qty, reserved: reserved - qty, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    return true;
  });
}

async function release(productId, qty) {
  const docRef = db.collection('inventory').doc(productId);
  return db.runTransaction(async (tx) => {
    const doc = await tx.get(docRef);
    if (!doc.exists) return false;
    const data = doc.data();
    const reserved = (data.reserved || 0);
    const newReserved = Math.max(0, reserved - qty);
    tx.update(docRef, { reserved: newReserved, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    return true;
  });
}

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
    const pid = 'script-prod-1';
    await seedInventory(pid, 5);

    // Reserve 3 -> should succeed
    const r1 = await reserve(pid, 3);
    if (!r1) throw new Error('Reserve 3 failed unexpectedly');
    log('Reserved 3');

    let doc = await getInventory(pid);
    await assertEqual(doc.reserved, 3, 'reserved should be 3 after first reserve');

    // Reserve 3 again -> should fail (only 2 left)
    const r2 = await reserve(pid, 3);
    if (r2) throw new Error('Reserve 3 succeeded unexpectedly when insufficient stock');
    log('Reserve 3 correctly failed due to insufficient available stock');

    // Release 2 -> reserved should go from 3 to 1
    await release(pid, 2);
    doc = await getInventory(pid);
    await assertEqual(doc.reserved, 1, 'reserved should be 1 after release of 2');

    // Finalize 1 -> stock 5 -> becomes 4, reserved becomes 0
    const f1 = await finalize(pid, 1);
    if (!f1) throw new Error('Finalize 1 failed unexpectedly');
    doc = await getInventory(pid);
    await assertEqual(doc.stock, 4, 'stock should be 4 after finalize of 1');
    await assertEqual(doc.reserved, 0, 'reserved should be 0 after finalize of 1');

    // Attempt to finalize 5 -> should fail (insufficient reserved)
    const f2 = await finalize(pid, 5);
    if (f2) throw new Error('Finalize 5 succeeded unexpectedly');
    log('Finalize 5 correctly failed due to insufficient reserved/stock');

    console.log('\n✅ Inventory flow script: PASS');
    process.exit(0);
  } catch (e) {
    console.error('\n❌ Inventory flow script: FAIL');
    console.error(e);
    process.exit(1);
  }
}

if (require.main === module) {
  run();
}
