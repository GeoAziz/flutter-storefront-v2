import 'package:hive_flutter/hive_flutter.dart';
import '../models/comparison_item.dart';

class ComparisonRepository {
  static const String boxName = 'comparison_box';
  static const int maxItems = 4;

  Box? _box;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the repository (opens the Hive box if needed).
  Future<void> init() async {
    if (_isInitialized) return;
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }
    _isInitialized = true;
  }

  /// Add item to comparison, respecting the max 4-item limit.
  /// Returns true if added successfully, false if limit reached.
  Future<bool> add(ComparisonItem item) async {
    if (!_isInitialized) await init();
    
    if (_box!.length >= maxItems && !_box!.containsKey(item.id)) {
      return false; // At max capacity
    }
    
    await _box!.put(item.id, item.toMap());
    return true;
  }

  Future<void> remove(String id) async {
    if (!_isInitialized) await init();
    await _box!.delete(id);
  }

  List<ComparisonItem> getAll() {
    if (!_isInitialized) throw StateError('Repository not initialized. Call init() first.');
    return _box!.values
        .map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return ComparisonItem.fromMap(map);
        })
        .toList();
  }

  bool contains(String id) {
    if (!_isInitialized) throw StateError('Repository not initialized. Call init() first.');
    return _box!.containsKey(id);
  }

  Future<void> clear() async {
    if (!_isInitialized) await init();
    await _box!.clear();
  }

  int count() {
    if (!_isInitialized) throw StateError('Repository not initialized. Call init() first.');
    return _box!.length;
  }

  bool isFull() {
    if (!_isInitialized) throw StateError('Repository not initialized. Call init() first.');
    return _box!.length >= maxItems;
  }
}
