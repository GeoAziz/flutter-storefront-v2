# Firebase Emulator Setup (local development)

This document explains how to run the Firebase Emulator Suite for local development and integration tests.

Prerequisites
- Install Node.js (>=14) and npm
- Install the Firebase CLI: `npm install -g firebase-tools`
- Install the FlutterFire CLI: `dart pub global activate flutterfire_cli`

Initialize Firebase project locally (optional)
1. From the repo root run `firebase init` and choose Firestore and Storage emulators, or create a `firebase.json` with the emulator configuration.

Starting the emulator

```bash
# From repo root (ensure firebase.json exists or project is configured)
firebase emulators:start --only firestore,storage,auth
```

Using emulator in Flutter integration tests
1. Start emulator with a scripted command or as part of CI job.
2. In tests, point the Firestore instance to localhost emulator using:

```dart
FirebaseFirestore.instance.settings = const Settings(host: 'localhost:8080', sslEnabled: false, persistenceEnabled: true);
// Storage emulator: FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
```

Security & Rules
- Emulators ignore production rules; ensure tests exercise realistic security flows and add Firestore Rules to `firestore.rules` for review.

Notes
- Emulator is recommended for development and CI. It avoids production usage and credentials exposure.
- For image uploads during tests, use the storage emulator and seed sample images.
