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

    test('CursorRequest: following nextCursor returns subsequent items; third fetch signals end-of-list', () async {
      final first = await repo.fetchProductsPaginated(CursorRequest(cursor: null, limit: 1));
      expect(first.items, isNotEmpty);
      expect(first.items.length, 1);
      expect(first.nextCursor, isNotNull);
      expect(first.hasMore, isTrue);

      final second = await repo.fetchProductsPaginated(CursorRequest(cursor: first.nextCursor, limit: 1));
      // The second call returns the last item. With the stub having exactly 2 items,
      // and limit=1, a full page is returned, so hasMore is still true (standard pagination).
      expect(second.items, isNotEmpty);
      expect(second.items.length, 1);
      expect(second.hasMore, isTrue); // Still true because we got a full page
      expect(second.nextCursor, isNotNull);

      // Third fetch: beyond the 2-item stub, so we get empty result and no cursor.
      final third = await repo.fetchProductsPaginated(CursorRequest(cursor: second.nextCursor, limit: 1));
      expect(third.items, isEmpty);
      expect(third.hasMore, isFalse);
      expect(third.nextCursor, isNull);
    });
  });
}
