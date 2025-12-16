import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'cache_provider.dart';

/// Simple Hive-backed cache implementation that stores JSON-serializable values.
/// Key format: arbitrary string. Values stored as JSON string along with expiry timestamp.
class HiveCache implements CacheProvider {
  static const _boxName = 'app_cache';
  Box<String>? _box;
  final String? _customPath;

  /// Optionally pass a custom path (useful for tests).
  HiveCache({String? customPath}) : _customPath = customPath;

  Future<void> _ensureInit() async {
    if (_box != null && _box!.isOpen) return;
    if (_customPath != null) {
      Hive.init(_customPath);
    } else {
      // Prefer Hive.initFlutter() on Flutter platforms, but fall back to a
      // safe temporary directory if the flutter plugin (path_provider) is not
      // available (e.g., in some test environments).
      try {
        await Hive.initFlutter();
      } catch (_) {
        final tmp = await Directory.systemTemp.createTemp('hive_fallback');
        Hive.init(tmp.path);
      }
    }
    _box = await Hive.openBox<String>(_boxName);
  }

  @override
  Future<void> init() async {
    await _ensureInit();
  }

  @override
  Future<T?> get<T>(String key) async {
    await _ensureInit();
    final raw = _box!.get(key);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      final expiryTs = m['expiry'] as int?;
      if (expiryTs != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryTs);
        if (DateTime.now().isAfter(expiry)) {
          await _box!.delete(key);
          return null;
        }
      }
      final value = m['value'];
      return value as T;
    } catch (_) {
      // If parsing fails, remove entry to avoid repeated failures.
      await _box!.delete(key);
      return null;
    }
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    await _ensureInit();
    final expiry = ttl == null ? null : DateTime.now().add(ttl).millisecondsSinceEpoch;
    final payload = jsonEncode({'value': value, 'expiry': expiry});
    await _box!.put(key, payload);
  }

  @override
  Future<void> delete(String key) async {
    await _ensureInit();
    await _box!.delete(key);
  }

  @override
  Future<void> clear() async {
    await _ensureInit();
    await _box!.clear();
  }

  @override
  Future<bool> contains(String key) async {
    await _ensureInit();
    final raw = _box!.get(key);
    if (raw == null) return false;
    try {
      final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
      final expiryTs = m['expiry'] as int?;
      if (expiryTs != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryTs);
        if (DateTime.now().isAfter(expiry)) {
          await _box!.delete(key);
          return false;
        }
      }
      return true;
    } catch (_) {
      await _box!.delete(key);
      return false;
    }
  }
}


