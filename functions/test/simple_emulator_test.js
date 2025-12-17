/**
 * Simple test to verify Firestore emulator data persistence
 */
const admin = require('firebase-admin');

async function main() {
  try {
    admin.initializeApp();
  } catch (e) {
    // already initialized
  }

  const firestore = admin.firestore();
  
  // Set emulator host
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log('📍 Connecting to Firestore emulator:', process.env.FIRESTORE_EMULATOR_HOST);
    firestore.settings({ host: process.env.FIRESTORE_EMULATOR_HOST, ssl: false });
  }

  const testRef = firestore.collection('test-collection').doc('test-doc-123');
  
  console.log('✏️ Writing test document...');
  await testRef.set({ name: 'Test', timestamp: admin.firestore.FieldValue.serverTimestamp() });
  
  console.log('📖 Reading test document back...');
  const snap = await testRef.get();
  
  if (snap.exists) {
    console.log('✅ SUCCESS: Document found!');
    console.log('   Data:', snap.data());
    process.exit(0);
  } else {
    console.log('❌ FAIL: Document not found!');
    process.exit(1);
  }
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(2);
});
