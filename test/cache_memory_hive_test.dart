import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:shop/services/cache/memory_cache.dart';
import 'package:shop/services/cache/hive_cache.dart';

void main() {
  group('Cache: Memory -> Hive integration', () {
    test('MemoryCache set/get works', () async {
      final mem = MemoryCache();
      await mem.init();
      await mem.set('k1', {'value': 42}, ttl: Duration(seconds: 2));
      final got = await mem.get<Map>('k1');
      expect(got, isNotNull);
      expect(got!['value'], 42);
    });

    test('HiveCache persist and expiry works', () async {
      final temp = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(temp.path);
      final cache = HiveCache();
      await cache.init();

      await cache.set('hk1', {'x': 'y'}, ttl: Duration(milliseconds: 500));
      final first = await cache.get<Map>('hk1');
      expect(first, isNotNull);
      expect(first!['x'], 'y');

      // wait for expiry
      await Future.delayed(Duration(milliseconds: 750));
      final after = await cache.get('hk1');
      expect(after, isNull);

      await cache.clear();
      // cleanup
      await Hive.close();
      await temp.delete(recursive: true);
    });
  });
}
