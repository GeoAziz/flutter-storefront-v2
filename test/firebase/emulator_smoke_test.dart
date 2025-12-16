import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

// This test is intended to run against the Firebase Emulator Suite.
// Start the emulator before running this test:
// firebase emulators:start --only firestore,auth,storage

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    // Point to emulator
    FirebaseFirestore.instance.settings = const Settings(host: 'localhost:8080', sslEnabled: false, persistenceEnabled: true);
  });

  test('emulator can read/write a document', () async {
    final col = FirebaseFirestore.instance.collection('test_emulator');
    final docRef = col.doc('smoke_test');

    await docRef.set({'hello': 'world', 'createdAt': FieldValue.serverTimestamp()});
    final snapshot = await docRef.get();
    expect(snapshot.exists, isTrue);
    expect(snapshot.data()?['hello'], 'world');

    // cleanup
    await docRef.delete();
  });
}
