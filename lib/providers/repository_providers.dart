import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/repository/product_repository.dart';
// Use the Firestore-backed repository for non-mock builds. The
// implementation uses the REST emulator when available and falls back to
// a deterministic stub.
import 'package:shop/repository/firestore_product_repository.dart';

// Toggle: set at compile time using --dart-define=USE_MOCK=true/false
const bool _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  if (_useMock) {
    return MockProductRepository();
  }
  // Use Firestore-backed repository in non-mock mode. This provides
  // cursor/page pagination backed by Firestore (interim offset-based
  // implementation for Sprint 1).
  // Return a Firestore-backed repository which will attempt to read from
  // the emulator/Firestore and fall back to a local deterministic stub.
  return FirestoreProductRepository();
});
