# Cloud Functions for flutter-storefront-v2

This folder contains Firebase Cloud Functions templates used by the app. It includes:

- `rateLimitedWrite` - a callable function that enforces a simple fixed-window per-user rate limit stored in Firestore and optionally performs a single write.
- `batchWrite` - a callable function that accepts an array of write operations and performs them in batched commits to reduce client->function invocations.

Why these exist
- Firestore Security Rules cannot perform arbitrary cross-document counting; server-side enforcement is needed for accurate rate-limiting.
- Batching reduces the number of invocations and Firestore writes, helping stay within Spark plan free quotas.

How to test locally with emulator

1. Install dependencies in `functions/`:

```bash
cd functions
npm install
```

2. Start the Firebase emulators (functions + firestore):

```bash
cd /path/to/your/project
firebase emulators:start --only functions,firestore
```

3. From your Flutter app you can point to the emulator for functions and firestore (see Firebase docs). Example in Dart:

```dart
// Point to local emulator (only for local testing)
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
FirebaseFunctions.instance.useFunctionsEmulator(origin: 'http://localhost:5001');

final callable = FirebaseFunctions.instance.httpsCallable('rateLimitedWrite');
final resp = await callable.call({
  'action': 'wishlist_add',
  'limit': 10,
  'windowSec': 60,
  'writePath': 'users/UID/wishlist/ITEM_ID',
  'writeData': {'addedAt': DateTime.now().toIso8601String(), 'itemId': 'ITEM_ID'}
});

print(resp.data);
```

Deployment

To deploy functions to your Firebase project:

```bash
cd functions
npm install
firebase deploy --only functions --project YOUR_PROJECT_ID
```

Notes & recommendations
- Monitor invocation counts in Firebase Console. Use batching and client-side debouncing to minimize calls.
- Consider moving to Blaze plan if invocation counts grow beyond free-tier limits.
- The provided rate limiter is a simple fixed-window approach—suitable for light to medium traffic. For heavy traffic or more precise throttling, consider using an external fast store (Redis) or a sliding window algorithm.
