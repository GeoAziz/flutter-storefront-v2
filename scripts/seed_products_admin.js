/**
 * Node-based seeder that uses the Firebase Admin SDK to write products to
 * Firestore. This bypasses security rules (Admin SDK) and is safe to use
 * against the local emulator. It requires `firebase-admin` to be installed.
 *
 * Usage:
 *   npm install firebase-admin
 *   # Ensure emulator host is set (default 127.0.0.1:8080)
 *   export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
 *   node scripts/seed_products_admin.js --count=10
 *
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

function parseArgs() {
  const out = { count: 30, project: undefined };
  process.argv.slice(2).forEach(arg => {
    if (arg.startsWith('--count=')) out.count = parseInt(arg.split('=')[1], 10);
    if (arg.startsWith('--project=')) out.project = arg.split('=')[1];
  });
  return out;
}

async function main() {
  const { count } = parseArgs();
  const dataPath = path.join(__dirname, '..', 'data', 'seed_products.json');
  if (!fs.existsSync(dataPath)) {
    console.error('data/seed_products.json not found');
    process.exit(2);
  }

  const raw = fs.readFileSync(dataPath, 'utf8');
  const parsed = JSON.parse(raw);
  const templates = parsed.products || [];
  if (!templates.length) {
    console.error('No template products found in data/seed_products.json');
    process.exit(3);
  }

  // If running against emulator, default the host to localhost:8080 so the
  // script is easier to run interactively. You can override by exporting
  // FIRESTORE_EMULATOR_HOST in your shell.
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
    console.warn('FIRESTORE_EMULATOR_HOST not set; defaulting to 127.0.0.1:8080');
  }

  // Initialize admin SDK. Prefer an on-disk service account key if present
  // (serviceAccountKey.json at repo root). This avoids relying on ADC in
  // developer machines and CI. Allow overriding the project id via --project
  // so the REST verification endpoint uses the same project id.
  const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
  const args = parseArgs();
  const requestedProject = args.project;
  if (fs.existsSync(serviceAccountPath)) {
    try {
      const serviceAccount = require(serviceAccountPath);
      const initOptions = { credential: admin.credential.cert(serviceAccount) };
      if (requestedProject) initOptions.projectId = requestedProject;
      admin.initializeApp(initOptions);
      console.log('Initialized Admin SDK with serviceAccountKey.json');
      if (requestedProject) console.log('Using project:', requestedProject);
    } catch (e) {
      console.warn('Failed to initialize Admin SDK with serviceAccountKey.json:', e.message || e);
      try {
        admin.initializeApp();
      } catch (e2) {
        // ignore
      }
    }
  } else {
    // Fall back to default initialization which may require ADC; warn user.
    try {
      const initOptions = {};
      if (requestedProject) initOptions.projectId = requestedProject;
      admin.initializeApp(initOptions);
    } catch (e) {
      console.error('Could not initialize Admin SDK. If targeting emulator, set FIRESTORE_EMULATOR_HOST and ensure credentials are available.');
      throw e;
    }
  }

  const db = admin.firestore();

  let created = 0;
  for (let i = 0; i < count; i++) {
    const t = templates[i % templates.length];
    const id = `p_${Date.now()}_${i}`;
    // Convert simple types; Admin SDK accepts plain JS objects
    try {
      await db.collection('products').doc(id).set(t);
      console.log('Created product', id);
      created++;
    } catch (err) {
      console.error('Failed to create', id, err.toString());
    }
  }

  console.log('Seeding complete. Created', created, 'products');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
