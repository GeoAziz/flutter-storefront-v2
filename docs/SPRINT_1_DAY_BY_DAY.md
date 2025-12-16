# Sprint 1 Day-by-Day Implementation Guide

**Phase:** Phase 6, Sprint 1  
**Duration:** 10 business days (2 weeks)  
**Team:** 2 developers  
**Objective:** Wishlist + Comparison features fully implemented and tested  
**Status:** 🚀 Ready to Execute

---

## Overview: Sprint 1 Structure

```
WEEK 1 (Jan 13-17)
├── Mon (Day 1):  Firebase Setup
├── Tue (Day 2):  Wishlist Model + Repository
├── Wed (Day 3):  Wishlist Repository (Batch Writes)
├── Thu (Day 4):  Wishlist Riverpod Providers
└── Fri (Day 5):  Wishlist UI Components

WEEK 2 (Jan 20-24)
├── Mon (Day 6):  Comparison Model + Repository
├── Tue (Day 7):  Comparison UI + Integration
├── Wed (Day 8):  Unit Testing (Wishlist + Comparison)
├── Thu (Day 9):  Performance Profiling
└── Fri (Day 10): Final Testing + Code Review
```

---

## DAY 1 (Monday, January 13): Firebase Setup & Environment

**Time Budget:** 8 hours  
**Goal:** Firebase configured and ready for development  
**Owner:** Lead Developer

### Morning (9 AM - 12 PM)

**9:00 AM - 9:30 AM: Team Standup & Planning**
- [ ] Review Phase 6 executive summary
- [ ] Discuss Firebase Spark Plan constraints (50k reads, 20k writes, 125k CF)
- [ ] Assign feature ownership (Dev 1: Wishlist, Dev 2: Comparison)
- [ ] Set daily meeting times (10 AM daily standup)

**9:30 AM - 10:30 AM: Firebase Project Verification**
- [ ] Open Firebase Console: https://console.firebase.google.com/
- [ ] Navigate to `poafix` project
- [ ] Verify Firestore Database exists (or create it)
- [ ] Check Authentication is enabled
- [ ] Verify Cloud Storage bucket
- [ ] Document Project ID: `poafix`
- [ ] Copy API Key: `AIzaSyBFNmUDrt5H0G8S5hyrDVvQfobVWbR6mkI`

**10:30 AM - 12 PM: Install Dependencies**
- [ ] Update `pubspec.yaml` with Firebase packages (see SPRINT_1_SETUP_GUIDE.md)
- [ ] Run `flutter pub get`
- [ ] Verify no conflicts: `flutter doctor`
- [ ] Build check: `flutter build apk --debug --verbose`

### Afternoon (1 PM - 5 PM)

**1:00 PM - 2:00 PM: Create Feature Branch**
- [ ] Run: `git checkout -b feat/phase-6-sprint1-wishlist-comparison`
- [ ] Push: `git push -u origin feat/phase-6-sprint1-wishlist-comparison`
- [ ] Create `.env.firebase` with credentials (see SPRINT_1_SETUP_GUIDE.md Part 1.3)
- [ ] Add `.env.firebase` to `.gitignore`

**2:00 PM - 3:30 PM: Firebase Service Setup**
- [ ] Create `lib/services/firebase_service.dart` (see SPRINT_1_SETUP_GUIDE.md)
- [ ] Create `lib/services/firebase_options.dart` (Flutter generates this)
- [ ] Update `lib/main.dart` to initialize Firebase
- [ ] Test: `flutter run` should complete without Firebase errors

**3:30 PM - 5:00 PM: Firestore Configuration**
- [ ] Create Firestore collections in Firebase Console:
  - `wishlists`
  - `products`
  - `users`
  - `analytics`
- [ ] Create Firestore indexes (see SPRINT_1_SETUP_GUIDE.md Part 3.2)
- [ ] Deploy security rules: `firebase deploy --only firestore:rules`
- [ ] Create daily usage log: `docs/SPRINT_1_DAILY_LOG.md`

### End of Day Checklist

- [ ] Firebase project verified
- [ ] `pubspec.yaml` updated with Firebase packages
- [ ] Feature branch created and pushed
- [ ] `firebase_service.dart` created
- [ ] `lib/main.dart` updated with Firebase init
- [ ] Firestore collections created
- [ ] Security rules deployed
- [ ] `flutter run` successful
- [ ] Commit: `git add . && git commit -m "chore: Initialize Firebase project and services"`

**Expected Firebase Usage:**
- Reads: ~20
- Writes: ~15
- CF Invocations: 0

---

## DAY 2 (Tuesday, January 14): Wishlist Model & Repository (Part 1)

**Time Budget:** 8 hours  
**Goal:** WishlistModel and HiveRepository created with local persistence  
**Owner:** Dev 1 (Wishlist Lead)

### Morning (9 AM - 12 PM)

**9:00 AM - 9:15 AM: Daily Standup**
- [ ] Review yesterday's completion status
- [ ] Discuss any Firebase setup issues
- [ ] Confirm Dev 1 owns Wishlist, Dev 2 owns Comparison
- [ ] Check Firebase usage against daily target

**9:15 AM - 10:00 AM: Create Models**

Create `lib/models/wishlist_model.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wishlist_model.freezed.dart';
part 'wishlist_model.g.dart';

@freezed
class WishlistItem with _$WishlistItem {
  const factory WishlistItem({
    required String id,
    required String productId,
    required String productName,
    required String imageUrl,
    required double price,
    required DateTime addedAt,
    required DateTime? removedAt,
    String? notes,
  }) = _WishlistItem;

  factory WishlistItem.fromJson(Map<String, dynamic> json) =>
      _$WishlistItemFromJson(json);
}

@freezed
class WishlistSyncStatus with _$WishlistSyncStatus {
  const factory WishlistSyncStatus({
    required bool isOnline,
    required int pendingWrites,
    required DateTime? lastSyncAt,
    String? lastError,
  }) = _WishlistSyncStatus;

  factory WishlistSyncStatus.fromJson(Map<String, dynamic> json) =>
      _$WishlistSyncStatusFromJson(json);
}
```

- [ ] Add `freezed` to `pubspec.yaml`:
  ```yaml
  dev_dependencies:
    freezed: ^2.4.0
    build_runner: ^2.4.0
  ```
- [ ] Generate freezed code: `flutter pub run build_runner build`

**10:00 AM - 11:00 AM: Create Hive Repository**

Create `lib/repositories/wishlist_repository.dart`:

```dart
import 'package:hive/hive.dart';
import 'package:shop/models/wishlist_model.dart';

class WishlistRepository {
  static const String _boxName = 'wishlist';
  late Box<WishlistItem> _box;
  
  Future<void> initialize() async {
    // Register HiveTypeAdapter (generate with build_runner)
    Hive.registerAdapter(WishlistItemAdapter());
    _box = await Hive.openBox<WishlistItem>(_boxName);
  }
  
  // Local operations (fast, offline)
  Future<void> addToWishlist(WishlistItem item) async {
    await _box.put(item.productId, item);
  }
  
  Future<void> removeFromWishlist(String productId) async {
    await _box.delete(productId);
  }
  
  Future<List<WishlistItem>> getWishlist() async {
    return _box.values.toList();
  }
  
  Future<bool> isInWishlist(String productId) async {
    return _box.containsKey(productId);
  }
  
  Future<int> getWishlistCount() async {
    return _box.length;
  }
  
  Future<void> clearWishlist() async {
    await _box.clear();
  }
}
```

- [ ] Create `lib/models/wishlist_adapter.dart` for Hive serialization
- [ ] Generate Hive adapters: `flutter pub run build_runner build`

**11:00 AM - 12:00 PM: Create Test File**

Create `test/repositories/wishlist_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shop/models/wishlist_model.dart';
import 'package:shop/repositories/wishlist_repository.dart';

void main() {
  group('WishlistRepository', () {
    late WishlistRepository repository;
    
    setUpAll(() async {
      // Setup test Hive instance
      const testDir = '.dart_tool/test_hive';
      Hive.init(testDir);
    });
    
    setUp(() async {
      repository = WishlistRepository();
      await repository.initialize();
    });
    
    tearDown(() async {
      await Hive.deleteBoxFromDisk('wishlist');
    });
    
    test('addToWishlist stores item', () async {
      final item = WishlistItem(
        id: '1',
        productId: 'p1',
        productName: 'Test Product',
        imageUrl: 'https://example.com/image.jpg',
        price: 99.99,
        addedAt: DateTime.now(),
        removedAt: null,
      );
      
      await repository.addToWishlist(item);
      final exists = await repository.isInWishlist('p1');
      
      expect(exists, true);
    });
    
    test('getWishlist returns all items', () async {
      // Add multiple items
      for (int i = 0; i < 3; i++) {
        await repository.addToWishlist(WishlistItem(
          id: '$i',
          productId: 'p$i',
          productName: 'Product $i',
          imageUrl: 'https://example.com/image.jpg',
          price: 99.99,
          addedAt: DateTime.now(),
          removedAt: null,
        ));
      }
      
      final items = await repository.getWishlist();
      expect(items.length, 3);
    });
    
    test('removeFromWishlist deletes item', () async {
      final item = WishlistItem(
        id: '1',
        productId: 'p1',
        productName: 'Test Product',
        imageUrl: 'https://example.com/image.jpg',
        price: 99.99,
        addedAt: DateTime.now(),
        removedAt: null,
      );
      
      await repository.addToWishlist(item);
      await repository.removeFromWishlist('p1');
      final exists = await repository.isInWishlist('p1');
      
      expect(exists, false);
    });
  });
}
```

### Afternoon (1 PM - 5 PM)

**1:00 PM - 2:00 PM: Run Tests**
- [ ] Run: `flutter test test/repositories/wishlist_repository_test.dart`
- [ ] All 3 tests should pass
- [ ] Check test coverage: `flutter test --coverage`

**2:00 PM - 3:00 PM: Code Review & Integration**
- [ ] Pair with Dev 2 for code review (30 mins)
- [ ] Ensure models follow project conventions
- [ ] Verify no hardcoded strings
- [ ] Check test coverage > 80%

**3:00 PM - 5:00 PM: Documentation & Commit**
- [ ] Update `lib/models/README.md` with WishlistModel documentation
- [ ] Document Hive adapter setup in `lib/repositories/README.md`
- [ ] Commit: `git add . && git commit -m "feat(wishlist): Add WishlistModel and HiveRepository"`
- [ ] Push: `git push origin feat/phase-6-sprint1-wishlist-comparison`

### End of Day Checklist

- [ ] `wishlist_model.dart` created with Freezed
- [ ] `wishlist_repository.dart` created with Hive
- [ ] 3 unit tests passing (100% coverage)
- [ ] Models documentation updated
- [ ] Code committed and pushed
- [ ] No Firebase writes (local operations only)

**Expected Firebase Usage:**
- Reads: 0 (all local)
- Writes: 0 (all local)
- CF Invocations: 0

**Cumulative Sprint Usage:** ~35 reads, ~15 writes, 0 CF

---

## DAY 3 (Wednesday, January 15): Wishlist Batch Write Logic

**Time Budget:** 8 hours  
**Goal:** Firestore sync and batch write logic implemented  
**Owner:** Dev 1 (Wishlist Lead)

### Morning (9 AM - 12 PM)

**9:00 AM - 9:15 AM: Daily Standup**
- [ ] Model creation completed successfully
- [ ] Discuss batch write strategy (debounce + queue)
- [ ] Review Firebase usage tracker

**9:15 AM - 11:00 AM: Create Batch Write Manager**

Create `lib/services/batch_write_manager.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BatchWriteManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int batchSize; // 5 items per batch
  final Duration debounceDelay; // 1 second
  
  List<Map<String, dynamic>> _writeQueue = [];
  Function? _debounceTimer;
  
  BatchWriteManager({
    this.batchSize = 5,
    this.debounceDelay = const Duration(seconds: 1),
  });
  
  /// Queue a write operation (debounced)
  void queueWrite(String collection, String docId, Map<String, dynamic> data) {
    _writeQueue.add({
      'collection': collection,
      'docId': docId,
      'data': data,
    });
    
    if (_writeQueue.length >= batchSize) {
      _flushBatch();
    } else {
      _debounceFlush();
    }
  }
  
  /// Flush pending writes (debounced)
  void _debounceFlush() {
    _debounceTimer?.call(); // Cancel previous timer
    _debounceTimer = Future.delayed(debounceDelay, _flushBatch);
  }
  
  /// Execute batch write to Firestore
  Future<void> _flushBatch() async {
    if (_writeQueue.isEmpty) return;
    
    try {
      final batch = _firestore.batch();
      
      for (final write in _writeQueue) {
        final ref = _firestore
            .collection(write['collection'])
            .doc(write['docId']);
        batch.set(ref, write['data'], SetOptions(merge: true));
      }
      
      await batch.commit();
      _writeQueue.clear();
    } catch (e) {
      print('Batch write error: $e');
      // Retain queue for retry
    }
  }
  
  /// Force flush immediately
  Future<void> flush() => _flushBatch();
}
```

**11:00 AM - 12:00 PM: Enhance Repository with Sync**

Update `lib/repositories/wishlist_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop/services/batch_write_manager.dart';

class WishlistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BatchWriteManager _batchManager;
  
  // ... existing code ...
  
  /// Sync wishlist to Firestore (with batching)
  Future<void> syncToFirestore(String userId) async {
    try {
      final items = await getWishlist();
      
      for (final item in items) {
        _batchManager.queueWrite(
          'wishlists/$userId/items',
          item.productId,
          item.toJson(),
        );
      }
      
      await _batchManager.flush();
    } catch (e) {
      print('Sync error: $e');
      rethrow;
    }
  }
  
  /// Load wishlist from Firestore
  Future<void> loadFromFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('wishlists')
          .doc(userId)
          .collection('items')
          .get();
      
      for (final doc in snapshot.docs) {
        final item = WishlistItem.fromJson(doc.data());
        await addToWishlist(item);
      }
    } catch (e) {
      print('Load error: $e');
      rethrow;
    }
  }
}
```

### Afternoon (1 PM - 5 PM)

**1:00 PM - 2:30 PM: Create Comprehensive Tests**

Create `test/services/batch_write_manager_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shop/services/batch_write_manager.dart';

void main() {
  group('BatchWriteManager', () {
    late BatchWriteManager manager;
    
    setUp(() {
      manager = BatchWriteManager(
        batchSize: 5,
        debounceDelay: Duration(milliseconds: 100),
      );
    });
    
    test('queues writes and flushes on batch full', () async {
      // Verify batching logic (mock Firestore)
      for (int i = 0; i < 5; i++) {
        manager.queueWrite('test', 'doc$i', {'value': i});
      }
      
      await Future.delayed(Duration(milliseconds: 200));
      
      // Queue should be empty after flush
      expect(manager.queueLength, 0);
    });
    
    test('debounces writes', () async {
      manager.queueWrite('test', 'doc1', {'value': 1});
      manager.queueWrite('test', 'doc2', {'value': 2});
      
      await Future.delayed(Duration(milliseconds: 50));
      expect(manager.queueLength, 2);
      
      await Future.delayed(Duration(milliseconds: 100));
      expect(manager.queueLength, 0); // Flushed after debounce
    });
  });
}
```

**2:30 PM - 3:30 PM: Run Full Test Suite**
- [ ] Run all tests: `flutter test`
- [ ] Target: 20+ tests passing
- [ ] Coverage: > 85%
- [ ] No failures

**3:30 PM - 5:00 PM: Firebase Integration Testing**
- [ ] Update `.env.firebase` with test credentials
- [ ] Create `test/integration/wishlist_sync_test.dart` for Firebase tests
- [ ] Commit: `git add . && git commit -m "feat(wishlist): Add batch write manager and Firestore sync"`

### End of Day Checklist

- [ ] `batch_write_manager.dart` created
- [ ] `wishlist_repository.dart` enhanced with sync
- [ ] 25+ unit tests passing
- [ ] Code coverage > 85%
- [ ] Firebase integration verified
- [ ] Code committed and pushed

**Expected Firebase Usage:**
- Reads: ~50
- Writes: ~40 (batch operations)
- CF Invocations: 0

**Cumulative Sprint Usage:** ~85 reads, ~55 writes, 0 CF

---

## DAY 4 (Thursday, January 16): Wishlist Riverpod Providers

**Time Budget:** 8 hours  
**Goal:** All Riverpod providers for wishlist state management implemented  
**Owner:** Dev 1 (Wishlist Lead)

### Morning (9 AM - 12 PM)

**9:00 AM - 9:15 AM: Daily Standup**
- [ ] Batch write logic working correctly
- [ ] Discuss provider architecture
- [ ] Review Firebase usage metrics

**9:15 AM - 11:30 AM: Create Wishlist Providers**

Create `lib/providers/wishlist_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/wishlist_model.dart';
import 'package:shop/repositories/wishlist_repository.dart';

// Singleton repository provider
final wishlistRepositoryProvider = Provider((ref) {
  return WishlistRepository();
});

// Watch all wishlist items
final watchWishlistProvider = StreamProvider<List<WishlistItem>>((ref) async* {
  final repository = ref.watch(wishlistRepositoryProvider);
  
  while (true) {
    final items = await repository.getWishlist();
    yield items;
    await Future.delayed(Duration(seconds: 1)); // Poll every second
  }
});

// Get wishlist count
final wishlistCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(wishlistRepositoryProvider);
  return repository.getWishlistCount();
});

// Check if product is in wishlist
final isInWishlistProvider = FutureProvider.family<bool, String>((ref, productId) async {
  final repository = ref.watch(wishlistRepositoryProvider);
  return repository.isInWishlist(productId);
});

// Add to wishlist (with side effects)
final addToWishlistProvider = FutureProvider.family<void, WishlistItem>((ref, item) async {
  final repository = ref.watch(wishlistRepositoryProvider);
  await repository.addToWishlist(item);
  // Invalidate the watch provider to refresh UI
  ref.invalidate(watchWishlistProvider);
  ref.invalidate(wishlistCountProvider);
});

// Remove from wishlist
final removeFromWishlistProvider = FutureProvider.family<void, String>((ref, productId) async {
  final repository = ref.watch(wishlistRepositoryProvider);
  await repository.removeFromWishlist(productId);
  ref.invalidate(watchWishlistProvider);
  ref.invalidate(wishlistCountProvider);
});

// Sync status provider
final wishlistSyncStatusProvider = StateProvider<WishlistSyncStatus>((ref) {
  return const WishlistSyncStatus(
    isOnline: true,
    pendingWrites: 0,
    lastSyncAt: null,
    lastError: null,
  );
});
```

**11:30 AM - 12:00 PM: Create Provider Tests**

Create `test/providers/wishlist_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/wishlist_model.dart';
import 'package:shop/providers/wishlist_provider.dart';

void main() {
  group('WishlistProvider', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    test('watchWishlistProvider emits items', () async {
      final wishlist = container.listen(watchWishlistProvider, (_, state) {});
      
      // Verify listener is registered
      expect(wishlist, isNotNull);
    });
    
    test('wishlistCountProvider returns correct count', () async {
      final count = await container.read(wishlistCountProvider.future);
      expect(count, isA<int>());
    });
  });
}
```

### Afternoon (1 PM - 5 PM)

**1:00 PM - 2:00 PM: Integration with UI Components (Prep)**
- [ ] Review ProductCard widget structure
- [ ] Design WishlistButton integration points
- [ ] Document Riverpod consumer patterns

**2:00 PM - 3:30 PM: Create Mock Tests**
- [ ] Create `test/mocks/mock_wishlist_repository.dart`
- [ ] Add Mockito to `pubspec.yaml`
- [ ] Create 10+ mock tests for provider interactions
- [ ] Run: `flutter test` (target: 35+ tests passing)

**3:30 PM - 5:00 PM: Code Review & Documentation**
- [ ] Pair review with Dev 2
- [ ] Document provider usage patterns
- [ ] Update `lib/providers/README.md`
- [ ] Commit: `git add . && git commit -m "feat(wishlist): Add Riverpod state management providers"`

### End of Day Checklist

- [ ] All Riverpod providers created (6+)
- [ ] Provider tests passing (10+)
- [ ] Mock repository created
- [ ] Code review completed
- [ ] Documentation updated
- [ ] Code committed and pushed

**Expected Firebase Usage:**
- Reads: ~30 (testing)
- Writes: ~20 (test data cleanup)
- CF Invocations: 0

**Cumulative Sprint Usage:** ~115 reads, ~75 writes, 0 CF

---

## DAY 5 (Friday, January 17): Wishlist UI Components

**Time Budget:** 8 hours  
**Goal:** WishlistButton, WishlistScreen, WishlistIcon fully built and integrated  
**Owner:** Dev 1 (Wishlist Lead)

### Morning (9 AM - 12 PM)

**9:00 AM - 9:15 AM: Daily Standup & Planning**
- [ ] Review Week 1 progress
- [ ] Discuss Week 2 Comparison feature timeline
- [ ] Check Firebase usage (target: <200 reads/writes by EOD)

**9:15 AM - 10:30 AM: Create WishlistButton Component**

Create `lib/components/wishlist_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/wishlist_model.dart';
import 'package:shop/providers/wishlist_provider.dart';

class WishlistButton extends ConsumerWidget {
  final WishlistItem item;
  final VoidCallback? onChanged;
  
  const WishlistButton({
    required this.item,
    this.onChanged,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(isInWishlistProvider(item.productId).future),
      builder: (context, snapshot) {
        final isInWishlist = snapshot.data ?? false;
        
        return IconButton(
          icon: Icon(
            isInWishlist ? Icons.favorite : Icons.favorite_border,
            color: isInWishlist ? Colors.red : Colors.grey,
          ),
          onPressed: () => _toggleWishlist(ref, isInWishlist),
        );
      },
    );
  }
  
  void _toggleWishlist(WidgetRef ref, bool isInWishlist) async {
    if (isInWishlist) {
      await ref.read(removeFromWishlistProvider(item.productId).future);
    } else {
      await ref.read(addToWishlistProvider(item).future);
    }
    onChanged?.call();
  }
}
```

**10:30 AM - 11:30 AM: Create WishlistScreen**

Create `lib/screens/wishlist/wishlist_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/wishlist_provider.dart';
import 'package:shop/components/network_image_with_loader.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(watchWishlistProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
      ),
      body: wishlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No items in wishlist yet'),
            );
          }
          
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return WishlistItemTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class WishlistItemTile extends ConsumerWidget {
  final WishlistItem item;
  
  const WishlistItemTile({required this.item, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: NetworkImageWithLoader(
        imageUrl: item.imageUrl,
        width: 60,
        height: 60,
      ),
      title: Text(item.productName),
      subtitle: Text('\$${item.price}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await ref.read(
            removeFromWishlistProvider(item.productId).future,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from wishlist')),
          );
        },
      ),
    );
  }
}
```

**11:30 AM - 12:00 PM: Create WishlistIcon Badge**

Create `lib/components/wishlist_icon.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/wishlist_provider.dart';

class WishlistIcon extends ConsumerWidget {
  final VoidCallback? onTap;
  
  const WishlistIcon({this.onTap, Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(wishlistCountProvider);
    
    return countAsync.when(
      loading: () => const Icon(Icons.favorite_border),
      error: (_, __) => const Icon(Icons.favorite_border),
      data: (count) => GestureDetector(
        onTap: onTap,
        child: Badge(
          label: Text('$count'),
          child: const Icon(Icons.favorite_border),
        ),
      ),
    );
  }
}
```

### Afternoon (1 PM - 5 PM)

**1:00 PM - 2:30 PM: Create UI Tests**

Create `test/components/wishlist_button_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/wishlist_button.dart';

void main() {
  group('WishlistButton', () {
    testWidgets('renders favorite icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WishlistButton(item: /* mock item */),
            ),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });
  });
}
```

**2:30 PM - 3:30 PM: Integrate into ProductCard**
- [ ] Update `lib/components/product/product_card.dart` to include WishlistButton
- [ ] Test integration: `flutter run` and verify button works
- [ ] Create integration test

**3:30 PM - 5:00 PM: Week 1 Wrap-Up**
- [ ] Run full test suite: `flutter test` (target: 40+ tests)
- [ ] Check code coverage: `flutter test --coverage`
- [ ] Create end-of-week summary
- [ ] Commit: `git add . && git commit -m "feat(wishlist): Add UI components and integration"`
- [ ] Document Week 1 learnings in `docs/SPRINT_1_WEEK1_SUMMARY.md`

### End of Week 1 Checklist

**Wishlist Feature - COMPLETE ✅**
- [ ] WishlistModel created with Freezed
- [ ] HiveRepository with local persistence
- [ ] BatchWriteManager for Firestore sync
- [ ] Riverpod providers for state management
- [ ] WishlistButton component
- [ ] WishlistScreen full implementation
- [ ] WishlistIcon with badge
- [ ] 40+ unit tests passing
- [ ] Code coverage > 85%
- [ ] Firebase integration verified
- [ ] All code committed and pushed

**Firebase Usage (Week 1):**
- Reads: ~150
- Writes: ~100
- CF Invocations: 0
- **Total Usage: 0.6% of monthly limits ✅**

**Lines of Code Added:**
- Models: ~100
- Repositories: ~200
- Providers: ~150
- Components: ~300
- Tests: ~500
- **Total: ~1,250 LOC**

---

## DAY 6 (Monday, January 20): Comparison Model & Repository (WEEK 2)

**Time Budget:** 8 hours  
**Goal:** ComparisonItem and ComparisonRepository (local-only) implemented  
**Owner:** Dev 2 (Comparison Lead)

### Morning (9 AM - 12 PM)

**9:00 AM - 9:15 AM: Daily Standup & Planning**
- [ ] Review Week 1 completion
- [ ] Celebrate Wishlist launch
- [ ] Discuss Comparison architecture (local-only, no Firebase)
- [ ] Review Firebase usage (50% lower than expected!)

**9:15 AM - 10:30 AM: Create Comparison Models**

Create `lib/models/comparison_model.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'comparison_model.freezed.dart';
part 'comparison_model.g.dart';

@freezed
class ComparisonItem with _$ComparisonItem {
  const factory ComparisonItem({
    required String productId,
    required String productName,
    required double price,
    required String imageUrl,
    required double rating,
    required Map<String, dynamic> specifications,
  }) = _ComparisonItem;

  factory ComparisonItem.fromJson(Map<String, dynamic> json) =>
      _$ComparisonItemFromJson(json);
}

@freezed
class ComparisonList with _$ComparisonList {
  const factory ComparisonList({
    required List<ComparisonItem> items,
    @Default(false) bool isMaxed, // Max 4 items
  }) = _ComparisonList;

  factory ComparisonList.fromJson(Map<String, dynamic> json) =>
      _$ComparisonListFromJson(json);
  
  int get itemCount => items.length;
  bool get canAddMore => items.length < 4;
}
```

**10:30 AM - 12:00 PM: Create Local Repository**

Create `lib/repositories/comparison_repository.dart`:

```dart
import 'package:hive/hive.dart';
import 'package:shop/models/comparison_model.dart';

class ComparisonRepository {
  static const String _boxName = 'comparison';
  static const int maxItems = 4;
  late Box<ComparisonItem> _box;
  
  Future<void> initialize() async {
    Hive.registerAdapter(ComparisonItemAdapter());
    _box = await Hive.openBox<ComparisonItem>(_boxName);
  }
  
  // Local operations (no Firestore)
  Future<void> addItem(ComparisonItem item) async {
    if (_box.length >= maxItems) {
      throw Exception('Comparison list full (max $maxItems items)');
    }
    await _box.put(item.productId, item);
  }
  
  Future<void> removeItem(String productId) async {
    await _box.delete(productId);
  }
  
  Future<List<ComparisonItem>> getComparison() async {
    return _box.values.toList();
  }
  
  Future<bool> isInComparison(String productId) async {
    return _box.containsKey(productId);
  }
  
  Future<void> clearComparison() async {
    await _box.clear();
  }
  
  Future<int> getItemCount() async {
    return _box.length;
  }
  
  Future<bool> canAddMore() async {
    return _box.length < maxItems;
  }
}
```

### Afternoon (1 PM - 5 PM)

**1:00 PM - 2:30 PM: Create Tests**

Create `test/repositories/comparison_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shop/models/comparison_model.dart';
import 'package:shop/repositories/comparison_repository.dart';

void main() {
  group('ComparisonRepository', () {
    late ComparisonRepository repository;
    
    setUpAll(() async {
      const testDir = '.dart_tool/test_hive';
      Hive.init(testDir);
    });
    
    setUp(() async {
      repository = ComparisonRepository();
      await repository.initialize();
    });
    
    tearDown(() async {
      await Hive.deleteBoxFromDisk('comparison');
    });
    
    test('addItem stores item', () async {
      final item = ComparisonItem(
        productId: 'p1',
        productName: 'Product 1',
        price: 99.99,
        imageUrl: 'url',
        rating: 4.5,
        specifications: {},
      );
      
      await repository.addItem(item);
      final exists = await repository.isInComparison('p1');
      expect(exists, true);
    });
    
    test('prevents adding more than 4 items', () async {
      for (int i = 0; i < 4; i++) {
        await repository.addItem(ComparisonItem(
          productId: 'p$i',
          productName: 'Product $i',
          price: 99.99,
          imageUrl: 'url',
          rating: 4.5,
          specifications: {},
        ));
      }
      
      // Fifth item should fail
      expect(
        () => repository.addItem(ComparisonItem(
          productId: 'p5',
          productName: 'Product 5',
          price: 99.99,
          imageUrl: 'url',
          rating: 4.5,
          specifications: {},
        )),
        throwsException,
      );
    });
    
    test('canAddMore returns correct status', () async {
      expect(await repository.canAddMore(), true);
      
      for (int i = 0; i < 4; i++) {
        await repository.addItem(ComparisonItem(
          productId: 'p$i',
          productName: 'Product $i',
          price: 99.99,
          imageUrl: 'url',
          rating: 4.5,
          specifications: {},
        ));
      }
      
      expect(await repository.canAddMore(), false);
    });
  });
}
```

**2:30 PM - 4:00 PM: Create Providers**

Create `lib/providers/comparison_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/comparison_model.dart';
import 'package:shop/repositories/comparison_repository.dart';

final comparisonRepositoryProvider = Provider((ref) {
  return ComparisonRepository();
});

final watchComparisonProvider = StreamProvider<List<ComparisonItem>>((ref) async* {
  final repo = ref.watch(comparisonRepositoryProvider);
  
  while (true) {
    final items = await repo.getComparison();
    yield items;
    await Future.delayed(Duration(seconds: 1));
  }
});

final comparisonCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(comparisonRepositoryProvider);
  return repo.getItemCount();
});

final canAddToComparisonProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(comparisonRepositoryProvider);
  return repo.canAddMore();
});

final addToComparisonProvider = FutureProvider.family<void, ComparisonItem>((ref, item) async {
  final repo = ref.watch(comparisonRepositoryProvider);
  await repo.addItem(item);
  ref.invalidate(watchComparisonProvider);
  ref.invalidate(comparisonCountProvider);
  ref.invalidate(canAddToComparisonProvider);
});

final removeFromComparisonProvider = FutureProvider.family<void, String>((ref, productId) async {
  final repo = ref.watch(comparisonRepositoryProvider);
  await repo.removeItem(productId);
  ref.invalidate(watchComparisonProvider);
  ref.invalidate(comparisonCountProvider);
  ref.invalidate(canAddToComparisonProvider);
});
```

**4:00 PM - 5:00 PM: Commit & Documentation**
- [ ] Run: `flutter test` (target: 50+ tests)
- [ ] Document comparison architecture
- [ ] Commit: `git add . && git commit -m "feat(comparison): Add ComparisonModel and Repository"`

### End of Day Checklist

- [ ] ComparisonModel created with Freezed
- [ ] ComparisonRepository with local persistence
- [ ] Max 4 items logic implemented
- [ ] 8+ unit tests passing
- [ ] Comparison Riverpod providers created
- [ ] Code committed

**Expected Firebase Usage:**
- Reads: ~20 (testing)
- Writes: 0 (local only)
- CF Invocations: 0

**Cumulative Sprint Usage:** ~170 reads, ~100 writes, 0 CF

---

## DAY 7 (Tuesday, January 21): Comparison UI & Integration

**Time Budget:** 8 hours  
**Goal:** ComparisonTable UI, ComparisonButton, and ProductCard integration complete  
**Owner:** Dev 2 (Comparison Lead)

### Morning (9 AM - 12 PM)

**9:00 AM - 9:15 AM: Daily Standup**

**9:15 AM - 11:00 AM: Create UI Components**

Create `lib/components/comparison_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/models/comparison_model.dart';
import 'package:shop/providers/comparison_provider.dart';

class ComparisonButton extends ConsumerWidget {
  final ComparisonItem item;
  final VoidCallback? onChanged;
  
  const ComparisonButton({
    required this.item,
    this.onChanged,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(isInComparisonProvider(item.productId).future),
      builder: (context, snapshot) {
        final isInComparison = snapshot.data ?? false;
        final canAddAsync = ref.watch(canAddToComparisonProvider);
        
        return canAddAsync.when(
          data: (canAdd) => IconButton(
            icon: Icon(
              isInComparison ? Icons.done_all : Icons.compare_arrows,
              color: isInComparison ? Colors.green : Colors.grey,
            ),
            onPressed: isInComparison || canAdd
                ? () => _toggleComparison(ref, isInComparison)
                : null,
          ),
          loading: () => const SizedBox(width: 24, height: 24),
          error: (_, __) => const Icon(Icons.compare_arrows),
        );
      },
    );
  }
  
  void _toggleComparison(WidgetRef ref, bool isInComparison) async {
    if (isInComparison) {
      await ref.read(removeFromComparisonProvider(item.productId).future);
    } else {
      await ref.read(addToComparisonProvider(item).future);
    }
    onChanged?.call();
  }
}
```

Create `lib/components/comparison_table.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/comparison_provider.dart';
import 'package:shop/components/network_image_with_loader.dart';

class ComparisonTable extends ConsumerWidget {
  const ComparisonTable({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(watchComparisonProvider);
    
    return comparisonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('Error: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No products to compare'));
        }
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Spec')),
              ...items.map((item) => DataColumn(
                label: Column(
                  children: [
                    NetworkImageWithLoader(
                      imageUrl: item.imageUrl,
                      width: 60,
                      height: 60,
                    ),
                    Text(item.productName, maxLines: 1),
                  ],
                ),
              )),
            ],
            rows: _buildRows(items),
          ),
        );
      },
    );
  }
  
  List<DataRow> _buildRows(List<ComparisonItem> items) {
    final specs = items.first.specifications.keys.toList();
    return specs.map((spec) {
      return DataRow(
        cells: [
          DataCell(Text(spec)),
          ...items.map((item) => DataCell(
            Text(item.specifications[spec]?.toString() ?? 'N/A'),
          )),
        ],
      );
    }).toList();
  }
}
```

**11:00 AM - 12:00 PM: Create ComparisonScreen**

Create `lib/screens/comparison/comparison_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/components/comparison_table.dart';
import 'package:shop/providers/comparison_provider.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(watchComparisonProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
      ),
      body: comparisonAsync.when(
        data: (items) => Column(
          children: [
            if (items.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('Comparing ${items.length} products'),
              ),
            Expanded(child: ComparisonTable()),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.clear_all),
        onPressed: () async {
          final repo = ref.read(comparisonRepositoryProvider);
          await repo.clearComparison();
        },
      ),
    );
  }
}
```

### Afternoon (1 PM - 5 PM)

**1:00 PM - 2:30 PM: Integrate into ProductCard**
- [ ] Update `lib/components/product/product_card.dart`
- [ ] Add both WishlistButton and ComparisonButton
- [ ] Test integration

**2:30 PM - 3:30 PM: Create Tests**
- [ ] Component tests for ComparisonButton
- [ ] Widget tests for ComparisonTable
- [ ] Target: 8+ new tests

**3:30 PM - 5:00 PM: Wrap-Up & Commit**
- [ ] Run full test suite (target: 60+ tests)
- [ ] Code coverage check
- [ ] Commit: `git add . && git commit -m "feat(comparison): Add UI components and integration"`

### End of Day Checklist

- [ ] ComparisonButton created
- [ ] ComparisonTable created
- [ ] ComparisonScreen created
- [ ] ProductCard integration complete
- [ ] 8+ tests passing
- [ ] Code committed

**Expected Firebase Usage:**
- Reads: ~15 (testing)
- Writes: 0
- CF Invocations: 0

**Cumulative Sprint Usage:** ~185 reads, ~100 writes, 0 CF

---

## DAY 8 (Wednesday, January 22): Unit Testing & Coverage

**Time Budget:** 8 hours  
**Goal:** 60+ tests passing, >85% code coverage for both features  
**Owner:** Both Devs

### Morning (9 AM - 12 PM)

**9:00 AM - 9:15 AM: Daily Standup**

**9:15 AM - 12:00 PM: Comprehensive Testing**
- [ ] Create additional tests for edge cases
- [ ] Mock Firestore operations
- [ ] Test error scenarios
- [ ] Add integration tests

Target: 60+ tests, >85% coverage

### Afternoon (1 PM - 5 PM)

**1:00 PM - 5:00 PM: Testing Continuation**
- [ ] Run: `flutter test --coverage`
- [ ] Generate coverage report
- [ ] Fix coverage gaps
- [ ] Document test results

**End of Day:** 60+ tests passing ✅

---

## DAY 9 (Thursday, January 23): Performance Profiling

**Time Budget:** 8 hours  
**Goal:** Memory <50MB, 60 FPS verified, Firebase usage documented  
**Owner:** Both Devs

### Morning & Afternoon

- [ ] Profile memory usage with wishlist + comparison active
- [ ] Verify <50MB target achieved
- [ ] Test FPS during scrolling and interactions
- [ ] Document performance baseline
- [ ] Create `docs/SPRINT_1_PERFORMANCE_REPORT.md`

---

## DAY 10 (Friday, January 24): Final Testing & Code Review

**Time Budget:** 8 hours  
**Goal:** All Sprint 1 code reviewed, tested, merged to develop  
**Owner:** Both Devs

### Morning

- [ ] Final test run: `flutter test` (target: 70+ tests)
- [ ] Code review: All PRs reviewed and approved
- [ ] Fix any remaining issues

### Afternoon

- [ ] Merge to develop branch
- [ ] Tag: `Sprint1-Complete`
- [ ] Create Sprint 1 completion report
- [ ] Plan Sprint 2 kickoff

---

## Sprint 1 Success Criteria

✅ **Wishlist Feature Complete**
- Local persistence with Hive
- Firestore sync with batch writes
- Riverpod state management
- UI components (Button, Screen, Icon)
- 15+ unit tests

✅ **Comparison Feature Complete**
- Local-only storage (no Firestore)
- Max 4 items validation
- Table UI component
- 10+ unit tests

✅ **Quality Metrics**
- 70+ tests passing
- >85% code coverage
- Memory <50MB
- 60 FPS maintained
- Firebase usage <200 reads/writes

✅ **Documentation**
- Code comments and docstrings
- Architecture documentation
- Performance report
- Daily usage log

✅ **Version Control**
- All code committed
- Sprint 1 PR merged to develop
- Tagged Sprint1-Complete

---

## Expected Sprint 1 Metrics

| Metric | Target | Expected | Status |
|--------|--------|----------|--------|
| **Tests** | 60+ | 70+ | ✅ |
| **Coverage** | 85% | 87% | ✅ |
| **Memory** | <50MB | ~45MB | ✅ |
| **FPS** | 60 | 58-60 | ✅ |
| **Firebase Reads** | <500 | ~185 | ✅ |
| **Firebase Writes** | <300 | ~100 | ✅ |
| **Dev Hours** | 80 | 75 | ✅ |
| **Lines of Code** | 2000 | ~2500 | ✅ |

---

## Notes & Best Practices

### Daily Workflow
1. Start: Pull latest, run tests
2. Work: Focus on one task at a time
3. Commit: Atomic commits with clear messages
4. End: Push changes, monitor Firebase usage

### Code Quality
- Always write tests before/during implementation
- Maintain >85% code coverage
- Use Riverpod best practices
- Follow Flutter conventions
- Document complex logic

### Firebase Optimization
- Monitor usage daily
- Batch writes when possible
- Use local Hive first
- Limit Firestore reads
- Cache aggressively

### Communication
- Daily 10 AM standup
- Pair programming on complex features
- Code review before merge
- Weekly summary email
- Update docs as you go

---

**Last Updated:** December 16, 2025  
**Status:** ✅ Ready to Execute  
**Next Milestone:** Sprint 1 Kickoff - January 13, 2026

Good luck, Team! 🚀

