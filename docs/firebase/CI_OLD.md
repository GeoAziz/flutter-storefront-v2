# CI Guidance for Firebase Emulator

To run integration tests in CI using the Firebase Emulator Suite, follow these steps:

1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

2. Start emulator in background or use dedicated job step
```bash
firebase emulators:start --only firestore,storage,auth --project=demo-project &
```

3. Run tests that target emulator
```bash
flutter test test/firebase/emulator_smoke_test.dart
```

4. Shut down emulator after tests
```bash
firebase emulators:stop
```

Notes for GitHub Actions
- Use `warrensbox/setup-node` to install node and npm
- Use `firebase-tools` to authenticate if using a real project; for emulator-only runs no auth required
- Ensure port availability (default: 8080 for firestore, 9199 for storage)

Example job snippet (YAML)
```yaml
- name: Start Firebase emulator
  run: firebase emulators:start --only firestore,storage,auth &
- name: Run tests
  run: flutter test test/firebase/emulator_smoke_test.dart
```
