// CacheProvider: abstract interface for pluggable cache backends.
// Implementations should be provided for Memory (dev/tests) and Hive (production).

abstract class CacheProvider {
  /// Initialize the provider. Safe to call multiple times.
  Future<void> init();

  /// Get a value previously stored under `key` or null if missing/expired.
  Future<T?> get<T>(String key);

  /// Store a value under `key`. Optional TTL will expire the entry after the duration.
  Future<void> set<T>(String key, T value, {Duration? ttl});

  /// Delete a single key.
  Future<void> delete(String key);

  /// Remove all entries (e.g., on sign-out).
  Future<void> clear();

  /// Whether the cache contains the given key and it's not expired.
  Future<bool> contains(String key);
}
