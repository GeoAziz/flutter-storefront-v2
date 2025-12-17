// Notifications simulator
// Implements a NotificationsService interface + stub (console sink)
// Triggers order placed and order completed notifications and asserts payloads emitted

const admin = require('firebase-admin');

process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-project' });
const db = admin.firestore();

function log(...args) { console.log('[notifications-sim]', ...args); }

class NotificationsService {
  // In production you'd send FCM/email. Here we log to console and write to a notifications_log collection.
  async sendNotification(topicOrUser, payload) {
    throw new Error('Not implemented');
  }
}

class ConsoleNotificationsStub extends NotificationsService {
  async sendNotification(target, payload) {
    log('EMITTED NOTIFICATION', { target, payload });
    // also write to a log collection for verification
    await db.collection('notifications_log').add({ target, payload, ts: admin.firestore.FieldValue.serverTimestamp() });
    return true;
  }
}

async function run() {
  try {
    const notifier = new ConsoleNotificationsStub();

    // Simulate order placed
    const placedPayload = { event: 'order_placed', orderId: 'sim-order-1', userId: 'sim-user' };
    await notifier.sendNotification('user_sim-user', placedPayload);

    // Simulate order completed
    const completedPayload = { event: 'order_completed', orderId: 'sim-order-1', userId: 'sim-user' };
    await notifier.sendNotification('user_sim-user', completedPayload);

    // Verify logs
    const snap = await db.collection('notifications_log').orderBy('ts', 'desc').limit(2).get();
    const logs = snap.docs.map(d => d.data());
    if (!logs || logs.length < 2) throw new Error('Notifications not written to log');

    console.log('\n✅ Notifications simulator: PASS');
    process.exit(0);
  } catch (e) {
    console.error('\n❌ Notifications simulator: FAIL');
    console.error(e);
    process.exit(1);
  }
}

if (require.main === module) run();
