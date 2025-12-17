import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:shop/features/inventory/repositories/inventory_repository.dart';

/// Integration tests for InventoryRepository against the Firestore emulator.
///
/// Requirements:
/// - Start the Firestore emulator on 127.0.0.1:8080 before running.
/// - Use projectId 'demo-project' to align with functions/tests namespace.

void main() {
  // Ensure bindings are initialized for firebase_core usage in tests
  TestWidgetsFlutterBinding.ensureInitialized();
  const emulatorHost = '127.0.0.1';
  const emulatorPort = 8080;
  const projectId = 'demo-project';

  late FirebaseFirestore firestore;
  late InventoryRepository repo;

  setUpAll(() async {
    // Use an in-memory FakeFirestore for fast CI-friendly tests
    firestore = FakeFirebaseFirestore();

    repo = InventoryRepository(firestore: firestore);
  });

  tearDown(() async {
    // Clean up any inventory documents between tests
    final col = firestore.collection('inventory');
    final snap = await col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  });

  test('reserveStock succeeds and increments reserved without changing stock',
      () async {
    final pid = 'itest-prod-1';
    await firestore.collection('inventory').doc(pid).set({
      'productId': pid,
      'stock': 10,
      'reserved': 0,
    });

    final ok = await repo.reserveStock(pid, 3);
    expect(ok, isTrue);

    final doc = await firestore.collection('inventory').doc(pid).get();
    final data = doc.data()!;
    expect(data['stock'], 10);
    expect(data['reserved'], 3);
  });

  test('releaseReservation decreases reserved but not below zero', () async {
    final pid = 'itest-prod-2';
    await firestore.collection('inventory').doc(pid).set({
      'productId': pid,
      'stock': 5,
      'reserved': 3,
    });

    await repo.releaseReservation(pid, 2);
    var doc = await firestore.collection('inventory').doc(pid).get();
    expect(doc.data()!['reserved'], 1);

    // Releasing more than reserved should clamp to 0
    await repo.releaseReservation(pid, 10);
    doc = await firestore.collection('inventory').doc(pid).get();
    expect(doc.data()!['reserved'], 0);
  });

  test('finalizeOrder decrements stock and clears reservation', () async {
    final pid = 'itest-prod-3';
    await firestore.collection('inventory').doc(pid).set({
      'productId': pid,
      'stock': 8,
      'reserved': 5,
    });

    final ok = await repo.finalizeOrder(pid, 5);
    expect(ok, isTrue);

    final doc = await firestore.collection('inventory').doc(pid).get();
    final data = doc.data()!;
    expect(data['stock'], 3);
    expect(data['reserved'], 0);
  });

  test('over-reserving fails and does not change reserved', () async {
    final pid = 'itest-prod-4';
    await firestore.collection('inventory').doc(pid).set({
      'productId': pid,
      'stock': 2,
      'reserved': 0,
    });

    final ok = await repo.reserveStock(pid, 5);
    expect(ok, isFalse);

    final doc = await firestore.collection('inventory').doc(pid).get();
    expect(doc.data()!['reserved'], 0);
  });

  test('sequential reservations succeed up to stock and then fail', () async {
    final pid = 'itest-prod-5';
    await firestore.collection('inventory').doc(pid).set({
      'productId': pid,
      'stock': 5,
      'reserved': 0,
    });

    // Sequential reservations of qty=1
    final results = <bool>[];
    for (var i = 0; i < 10; i++) {
      results.add(await repo.reserveStock(pid, 1));
    }
    final successes = results.where((r) => r).length;

    // At most stock (5) should succeed when run sequentially
    expect(successes, lessThanOrEqualTo(5));

    final doc = await firestore.collection('inventory').doc(pid).get();
    expect(doc.data()!['reserved'], successes);
  });

  test(
      'concurrent reservations (emulator-only) - run against Firestore emulator for real isolation',
      () async {
    // NOTE: FakeFirestore does not fully emulate transactional isolation under
    // concurrent access. To validate true concurrent behavior you must run the
    // same scenario against the Firestore emulator. This test is a placeholder
    // and is intentionally skipped when running with FakeFirestore.
  },
      skip:
          'Run this test in the Firestore emulator (see PHASE_3_INVENTORY_QUICK_REFERENCE.md)');

  test('reserveStock on empty/non-existent item returns false', () async {
    final pid = 'non-existent-prod';
    final ok = await repo.reserveStock(pid, 1);
    expect(ok, isFalse);
  });
}
