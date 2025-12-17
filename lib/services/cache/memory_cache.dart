import 'dart:async';

import 'cache_provider.dart';

class _CacheEntry {
  final dynamic value;
  final DateTime? expiry;

  _CacheEntry(this.value, this.expiry);

  bool get isExpired => expiry != null && DateTime.now().isAfter(expiry!);
}

/// Simple in-memory cache implementation with optional TTL.
/// This is safe for dev, tests, and as a fallback when persistent storage is unavailable.
class MemoryCache implements CacheProvider {
  final Map<String, _CacheEntry> _store = {};
  bool _initialized = false;

  @override
  Future<void> init() async {
    _initialized = true;
    // No async work required for memory cache, but keep async signature for parity.
  }

  @override
  Future<T?> get<T>(String key) async {
    if (!_initialized) await init();
    final e = _store[key];
    if (e == null) return null;
    if (e.isExpired) {
      _store.remove(key);
      return null;
    }
    return e.value as T;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    if (!_initialized) await init();
    final expiry = ttl == null ? null : DateTime.now().add(ttl);
    _store[key] = _CacheEntry(value, expiry);
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<bool> contains(String key) async {
    final e = _store[key];
    if (e == null) return false;
    if (e.isExpired) {
      _store.remove(key);
      return false;
    }
    return true;
  }
}
