import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/product_repository.dart';
import 'package:shop/repository/pagination.dart';
import 'package:shop/services/service_locator.dart';
import 'package:shop/services/telemetry/telemetry_service.dart';

class MockTelemetry implements TelemetryService {
  final List<Map<String, dynamic>> events = [];
  final List<Object> spans = [];

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace, {Map<String, dynamic>? context}) async {
    events.add({'name': 'captureException', 'error': error.toString(), 'context': context});
  }

  @override
  Future<void> finishSpan(Object? token) async {
    spans.add({'finish': token});
  }

  @override
  Future<void> init({Map<String, dynamic>? options}) async {}

  @override
  Future<Object?> startSpan(String name) async {
    final token = {'name': name, 'ts': DateTime.now().microsecondsSinceEpoch};
    spans.add(token);
    return token;
  }

  @override
  Future<void> logEvent(String name, Map<String, dynamic>? properties) async {
    events.add({'name': name, 'properties': properties});
  }

  @override
  Future<void> setUser({String? id, String? email}) async {}
}

void main() {
  group('Telemetry integration', () {
    test('pagination emits start and success events', () async {
      final repo = MockProductRepository();
      final mock = MockTelemetry();
      setTelemetryServiceForTest(mock);

      final res = await repo.fetchProductsPaginated(PageRequest(page: 1, pageSize: 1));
      expect(res.items.length, 1);

      // We expect at least start and success events recorded
      final names = mock.events.map((e) => e['name']).toList();
      expect(names, contains('pagination_start'));
      expect(names, contains('pagination_success'));
    });

    test('pagination error triggers captureException and pagination_error', () async {
      // Create a repository that throws inside fetchProducts
      final repo = _ThrowingRepository();
      final mock = MockTelemetry();
      setTelemetryServiceForTest(mock);

      try {
        await repo.fetchProductsPaginated(PageRequest(page: 1, pageSize: 1));
        fail('expected exception');
      } catch (_) {}

      final names = mock.events.map((e) => e['name']).toList();
      expect(names, contains('pagination_start'));
  expect(names, contains('pagination_error'));
  // captureException should also have been called
  expect(names, contains('captureException'));
    });
  });
}

class _ThrowingRepository extends ProductRepository {
  @override
  Future<List<Product>> fetchProducts() async {
    throw StateError('network failure');
  }

  @override
  Future<PaginationResult<Product>> fetchProductsPaginated(PaginationRequest request) {
    // Delegate to default implementation which will call fetchProducts and therefore throw.
    return super.fetchProductsPaginated(request);
  }
}
