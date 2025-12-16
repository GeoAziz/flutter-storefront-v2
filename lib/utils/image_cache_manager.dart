import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'device_cache_config.dart';

/// App-level cache manager for network images.
///
/// Controls disk cache size and eviction so images do not grow unbounded.
/// Adapts cache limits based on device capabilities (high-end, mid-range, low-end).
/// 
/// Current configuration: Mid-range device (safe default).
/// For adaptive configuration, use [createAdaptiveCacheManager] during app init.
final CacheManager appImageCacheManager = CacheManager(
  Config(
    'appImageCache',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 200, // Mid-range default
  ),
);

/// Creates a cache manager with device-adaptive limits.
///
/// Call this during app initialization to detect device capabilities
/// and adjust cache limits accordingly.
///
/// Example:
/// ```dart
/// final cacheManager = await createAdaptiveCacheManager();
/// ```
Future<CacheManager> createAdaptiveCacheManager() async {
  final config = await DeviceCacheConfig.adaptive();
  return CacheManager(
    Config(
      'appImageCache',
      stalePeriod: config.diskCacheStalePeriod,
      maxNrOfCacheObjects: config.diskCacheObjectCount,
    ),
  );
}

