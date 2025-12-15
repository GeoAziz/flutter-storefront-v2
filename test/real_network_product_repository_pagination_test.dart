import 'package:flutter_test/flutter_test.dart';
import 'package:shop/repository/real_product_repository.dart';
import 'package:shop/repository/pagination.dart';

void main() {
  group('RealProductRepository (interim cursor behavior)', () {
    final repo = RealProductRepository();

    test('CursorRequest: first page returns nextCursor when there is more', () async {
      final res = await repo.fetchProductsPaginated(CursorRequest(cursor: null, limit: 1));
      expect(res.items, isNotEmpty);
      expect(res.items.length, 1);
      expect(res.nextCursor, isNotNull);
      expect(res.hasMore, isTrue);
    });

    test('CursorRequest: following nextCursor returns subsequent items and then no nextCursor', () async {
      final first = await repo.fetchProductsPaginated(CursorRequest(cursor: null, limit: 1));
      expect(first.nextCursor, isNotNull);

      final second = await repo.fetchProductsPaginated(CursorRequest(cursor: first.nextCursor, limit: 1));
      // Our stub repo has only two items; the second call should return the last
      // item and no further cursor.
      expect(second.items, isNotEmpty);
      expect(second.items.length, 1);
      expect(second.nextCursor, isNull);
      expect(second.hasMore, isFalse);
    });
  });
}
