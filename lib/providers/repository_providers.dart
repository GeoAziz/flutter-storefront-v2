import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/repository/product_repository.dart';

// Toggle: set at compile time using --dart-define=USE_MOCK=true/false
const bool _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  if (_useMock) {
    return MockProductRepository();
  }
  return RealProductRepository();
});
