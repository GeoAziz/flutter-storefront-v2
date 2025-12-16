import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// App-level cache manager for network images.
///
/// Controls disk cache size and eviction so images do not grow unbounded.
/// Adjust `maxSize` (in bytes) and `maxNrOfCacheObjects` as needed for your
/// app budget. Current target: ~50 MB disk cache.
final CacheManager appImageCacheManager = CacheManager(
  Config(
    'appImageCache',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200,
  ),
);
