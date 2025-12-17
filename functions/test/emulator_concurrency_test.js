/**
 * Emulator-only concurrency test for inventory reservations.
 *
 * - Connects to the Firestore emulator at 127.0.0.1:8080
 * - Performs N concurrent transactions attempting to reserve 1 unit
 * - Asserts final reserved <= stock and stock unchanged
 *
 * Usage (from repo root):
 * 1) Start Firestore emulator:
 *    firebase emulators:start --only firestore
 * 2) Run this test (from repo root):
 *    node functions/test/emulator_concurrency_test.js
 *
 * Note: This is emulator-only and Spark-plan friendly. Do not run against production.
 */

const admin = require('firebase-admin');

// Ensure we use the emulator project namespace used elsewhere in the repo
const PROJECT_ID = process.env.FIRESTORE_PROJECT_ID || 'demo-project';

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

// Point to emulator host explicitly in case env vars are not set
db.settings({ host: '127.0.0.1:8080', ssl: false });

async function main() {
  const pid = process.env.TEST_PRODUCT_ID || 'emul-conc-prod';
  const initialStock = parseInt(process.env.TEST_STOCK || '5', 10);
  const attempts = parseInt(process.env.TEST_ATTEMPTS || '10', 10);
  const qty = parseInt(process.env.TEST_QTY || '1', 10);

  const ref = db.collection('inventory').doc(pid);
  console.log('Seeding inventory doc:', pid, 'stock=', initialStock);
  await ref.set({ productId: pid, stock: initialStock, reserved: 0 });

  // Launch concurrent transactions
  const workers = [];
  for (let i = 0; i < attempts; i++) {
    workers.push(
      db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists) return false;
        const data = snap.data();
        const stock = data.stock;
        const reserved = data.reserved || 0;
        if (stock - reserved >= qty) {
          tx.update(ref, { reserved: reserved + qty });
          return true;
        }
        return false;
      }).catch((err) => {
        console.error('Transaction error:', err.message || err);
        return false;
      })
    );
  }

  const results = await Promise.all(workers);
  const successes = results.filter((r) => r).length;

  const final = (await ref.get()).data();
  console.log('Results: attempts=', attempts, 'successes=', successes, 'final=', final);

  if (final.reserved !== successes) {
    console.error('FAIL: reserved mismatch: reserved=', final.reserved, ' successes=', successes);
    process.exitCode = 2;
    return;
  }

  if (final.stock !== initialStock) {
    console.error('FAIL: stock changed unexpectedly:', final.stock, 'expected', initialStock);
    process.exitCode = 3;
    return;
  }

  if (final.reserved > initialStock) {
    console.error('FAIL: overbooked: reserved > stock');
    process.exitCode = 4;
    return;
  }

  console.log('✅ Emulator concurrency test passed');
}

main().catch((err) => {
  console.error('Test failed with error:', err);
  process.exit(1);
});
