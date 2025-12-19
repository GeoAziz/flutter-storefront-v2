# Product Seeding Guide

This guide explains how to run the product seeding script against the Firestore emulator.

Important: by default Firestore security rules allow only admins to write to `products/`.
The seeding script uses the Firestore REST API and will be blocked by security rules unless:

- You run the seeder while the emulator is running and your rules allow write access (for development).
- Or run the script using an admin path (use emulator import/export or the Admin SDK).

Recommended local workflow (emulator + seeder):

1. Start the Firebase emulator from project root (ensure `firebase.json` includes `auth` and `firestore`):

```bash
firebase emulators:start --only auth,firestore --project demo-project
```

2. While the emulator is running, adjust `lib/config/firestore.rules` temporarily to allow writes to `products/` if you don't have an admin user set up locally. Example (temporary dev rule):

```text
match /products/{productId} {
  allow read: if true;
  allow create: if true; // TEMPORARY: remove after seeding
  allow update, delete: if request.auth.uid != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

3. Run the seeder (defaults to `demo-project` and 30 products):

```bash
bash scripts/run_seed_products.sh demo-project 30
```

4. After seeding, revert any temporary rule relaxations and re-start the emulator.

Alternative (preferred for CI):

- Prepare a Firestore export JSON and import it to the emulator using `firebase emulators:start --import=./emulator-export`.
- Use a CI step to seed data via the Admin SDK (server credentials) which bypass rules.

Notes:

- The seeder posts documents with the fields defined in `data/seed_products.json`.
- If you prefer to seed using the SDK, let me scaffold a `scripts/seed_products_sdk.dart` that initializes Firebase using service account credentials and writes documents via the Admin SDK.

## Admin seeding (recommended for local emulator)

If your security rules prevent client-side creation of `products/` (recommended), use the Admin SDK to seed the emulator. This bypasses rules and is the recommended local workflow.

1. Install Node dependencies (once):

```bash
npm install
```

2. Set the emulator host environment variable and run the admin seeder (example creates 10 products):

```bash
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
npm run seed-admin
```

Note: The project includes a `serviceAccountKey.json` at the repository root which the admin seeder will use automatically if present. You can also set `GOOGLE_APPLICATION_CREDENTIALS` to point to your service account file instead.


3. Alternatively, use the provided wrapper which will detect USE_ADMIN_SEEDER:

```bash
# Use the admin seeder
USE_ADMIN_SEEDER=true bash scripts/run_seed_products.sh demo-project 10

# Or run the Dart seeder (may be blocked by rules)
bash scripts/run_seed_products.sh demo-project 10
```

4. Verify documents with the REST endpoint:

```bash
curl -s "http://127.0.0.1:8080/v1/projects/demo-project/databases/(default)/documents/products?pageSize=5" | jq '.documents | length'
```

