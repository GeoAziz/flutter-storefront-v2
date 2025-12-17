# Week 2 UI Integration Quick Reference

## 🚀 TL;DR Setup (60 seconds)

```bash
# Terminal 1: Start emulators
firebase emulators:start --only functions,firestore

# Terminal 2: Run tests (optional, ~30s)
./scripts/automated_test.sh --no-build

# Terminal 3: Run app
flutter run
```

---

## 📦 Available Riverpod Providers

### Auth
```dart
final authProvider = StateNotifierProvider<AuthService, AuthState>((ref) => ...);
final currentUserProvider = FutureProvider<UserProfile?>((ref) => ...);
```

**Usage in widgets:**
```dart
final authState = ref.watch(authProvider);
final user = ref.watch(currentUserProvider);
```

### Products
```dart
final productProvider = FutureProvider<List<Product>>((ref) => ...);
final productPaginationProvider = FutureProvider<PaginationResult<Product>>((ref) => ...);
```

**Usage:**
```dart
final products = ref.watch(productProvider);
products.when(
  data: (items) => ListView(children: items.map(...)),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

### Cart
```dart
final cartProvider = StateNotifierProvider<CartService, UserCart>((ref) => ...);
```

**Usage:**
```dart
final cart = ref.watch(cartProvider);
ref.read(cartProvider.notifier).addItem(product);
```

### Orders
```dart
final orderProvider = FutureProvider<List<Order>>((ref) => ...);
```

### Favorites
```dart
final favoriteProvider = StateNotifierProvider<FavoritesService, UserFavorites>((ref) => ...);
```

---

## 🎨 Common UI Patterns

### 1. Product List with Loading State
```dart
class ProductListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productProvider);
    
    return productsAsync.when(
      data: (products) => GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: products.length,
        itemBuilder: (ctx, i) => ProductCard(product: products[i]),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Failed to load products: $error'),
      ),
    );
  }
}
```

### 2. Add to Cart
```dart
ElevatedButton(
  onPressed: () {
    ref.read(cartProvider.notifier).addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to cart')),
    );
  },
  child: Text('Add to Cart'),
)
```

### 3. Real-time Cart Count Badge
```dart
Consumer(
  builder: (context, ref, child) {
    final cart = ref.watch(cartProvider);
    return Badge(
      label: Text('${cart.items.length}'),
      child: Icon(Icons.shopping_cart),
    );
  },
)
```

### 4. Authentication Check
```dart
final currentUser = ref.watch(currentUserProvider);
currentUser.when(
  data: (user) {
    if (user == null) {
      return LoginScreen();
    }
    return HomeScreen();
  },
  loading: () => SplashScreen(),
  error: (_, __) => ErrorScreen(),
);
```

---

## 🔧 Backend Services API

### AuthService
```dart
// Sign up
await authService.signUp(email, password);

// Sign in
await authService.signIn(email, password);

// Get current user
final user = await authService.getCurrentUser();

// Update profile
await authService.updateProfile(name, phone);

// Sign out
await authService.signOut();
```

### FirestoreService
```dart
// Read single document
final product = await fsService.getDocument<Product>('products', productId);

// Read collection
final products = await fsService.getCollection<Product>('products');

// Write document
await fsService.setDocument('products', productId, productData);

// Update document
await fsService.updateDocument('products', productId, updates);

// Delete document
await fsService.deleteDocument('products', productId);

// Real-time listener
fsService.streamDocument<Product>('products', productId).listen((product) {
  // Handle real-time update
});

// Transaction
await fsService.transaction((tx) async {
  // Transactional operations
});

// Batch write
await fsService.batchWrite([(op1), (op2), ...]);
```

### OfflineSyncService
```dart
// Add to offline queue
await syncService.queueOperation('set', 'orders', orderId, orderData);

// Sync when online
await syncService.syncPendingOperations();

// Get sync status
final isSyncing = syncService.isSyncing;
```

---

## 🧪 Testing Tips

### Use Emulator UI While Developing
```
http://127.0.0.1:4000/
```
- View collections in real-time
- Inspect documents before/after writes
- Check security rule violations

### Debug Prints
```dart
print('AuthState: ${ref.watch(authProvider)}');
print('Cart items: ${ref.watch(cartProvider).items.length}');
```

### Check Emulator Logs
```bash
# Terminal running emulator shows all logs
# Look for "functions: ..." or "firestore: ..." messages
```

---

## ⚠️ Common Mistakes

❌ **DON'T**: Call providers outside `build()` or `ConsumerWidget`
```dart
// WRONG
class MyWidget extends StatelessWidget {
  final data = ref.watch(provider); // ❌ Can't access ref here
}
```

✅ **DO**: Use `ConsumerWidget` or `Consumer`
```dart
// RIGHT
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(provider); // ✅ Can access ref here
  }
}
```

---

❌ **DON'T**: Forget to handle loading/error states
```dart
// WRONG - will crash on loading
final data = ref.watch(futureProvider);
return Text(data.toString()); // ❌ Data might be loading!
```

✅ **DO**: Use `.when()` or `.maybeWhen()`
```dart
// RIGHT
final data = ref.watch(futureProvider);
return data.when(
  data: (d) => Text(d.toString()),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

---

❌ **DON'T**: Leave debug prints in production code
```dart
// WRONG
print('Debug: $data'); // ❌ Will show in logs
```

✅ **DO**: Use conditional logging
```dart
// RIGHT
if (kDebugMode) {
  print('Debug: $data'); // ✅ Only in debug builds
}
```

---

## 📊 Performance Checklist

- [ ] Use pagination for lists (don't load all products)
- [ ] Cache images with `CachedNetworkImage`
- [ ] Debounce search queries
- [ ] Lazy-load screens (don't build off-screen content)
- [ ] Use `const` constructors where possible
- [ ] Avoid rebuilding entire trees with `Consumer` scope
- [ ] Profile with DevTools: `flutter pub global activate devtools`

---

## 🐛 Debugging

### Enable Verbose Logging
```bash
flutter run -v
```

### Open DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Check Firestore Rules Violations
1. Open Emulator UI: http://127.0.0.1:4000/
2. Go to Firestore tab
3. Simulate a read/write to see rule rejection messages

### Inspect Network Calls
```dart
// In main.dart before Firebase.initializeApp():
if (kDebugMode) {
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50000000, // 50 MB
  );
}
```

---

## 📋 Before Commit

```bash
# Format code
flutter format lib/ test/

# Analyze for issues
flutter analyze

# Run tests (if any)
flutter test

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release
```

---

## 🔗 Helpful Links

- **Firebase Console**: https://console.firebase.google.com/project/poafix
- **Firestore Docs**: https://firebase.google.com/docs/firestore
- **Riverpod Docs**: https://riverpod.dev
- **Flutter Docs**: https://flutter.dev/docs
- **VS Code Shortcuts**: https://code.visualstudio.com/docs/editor/codebasics

---

## 🎯 Week 2 Tasks Checklist

- [ ] Wire ProductListScreen to `productProvider`
- [ ] Wire CartScreen to `cartProvider`
- [ ] Wire OrdersScreen to `orderProvider`
- [ ] Wire FavoritesScreen to `favoriteProvider`
- [ ] Implement authentication flow in UI
- [ ] Add real-time cart/favorites updates
- [ ] Handle loading and error states
- [ ] Test offline behavior (if offline sync implemented)
- [ ] Optimize images and pagination
- [ ] Run flutter analyze before committing

---

**Good luck with Week 2! 🚀**

For questions, refer to:
- `AUTOMATED_TESTING.md` (testing guide)
- `SPRINT_2_COMPLETION_VERIFIED.md` (full summary)
- `functions/README.md` (Cloud Functions)
- Code comments in `lib/services/` and `lib/providers/`
