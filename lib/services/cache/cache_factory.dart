import 'cache_provider.dart';
import 'memory_cache.dart';
import 'hive_cache.dart';
import '../feature_flags.dart';

/// Factory to get the appropriate cache provider based on runtime feature flags.
CacheProvider getCacheProvider() {
  if (kEnablePersistentCache) {
    return HiveCache();
  }
  return MemoryCache();
}
