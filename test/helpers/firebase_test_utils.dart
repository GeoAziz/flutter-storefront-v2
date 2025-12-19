// Test helper scaffolding for initializing a fake Firestore/Firebase app in
// widget/unit tests. This file uses `fake_cloud_firestore` and `firebase_core`
// helpers. Add to `dev_dependencies` in `pubspec.yaml`:
//
// dev_dependencies:
//   fake_cloud_firestore: ^1.0.0
//   firebase_core: any
//
// Example usage in a test:
//   final fs = FakeFirebaseFirestore();
//   // provide to your repositories or inject via provider overrides

// Minimal helper exported for convenience.
library test_helpers.firebase;

// Note: we avoid importing here to keep this file a scaffold. If you add
// `fake_cloud_firestore` to dev_dependencies, uncomment the imports below.
// import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// FakeFirebaseFirestore initFakeFirestore() => FakeFirebaseFirestore();

/// If you prefer, paste this helper into your test file directly to avoid
/// adding a dev dependency: create a small in-memory JSON-backed mock that
/// implements the subset of Firestore API your repository uses.
