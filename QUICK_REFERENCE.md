# Firebase & Riverpod Quick Reference Guide

**Project**: PoAFix E-Commerce  
**Firebase Project**: poafix  
**Last Updated**: December 16, 2025

---

## 🔐 Authentication Usage

### Sign Up New User
```dart
final result = await ref.read(
  signUpProvider(
    SignUpParams(
      email: 'user@example.com',
      password: 'SecurePassword123!',
      displayName: 'John Doe',
    ),
  ).future,
);
// Returns: User object on success
// Throws: AuthenticationException on error
```

### Sign In Existing User
```dart
final user = await ref.read(
  signInProvider(
    SignInParams(
      email: 'user@example.com',
      password: 'SecurePassword123!',
    ),
  ).future,
);
// Returns: User object on success
```

### Sign In Anonymously
```dart
final user = await ref.read(anonymousSignInProvider.future);
// Temporary account - should convert to email later
```

### Watch Authentication State
```dart
final authState = ref.watch(authStateProvider);
// AsyncValue<User?> - updates when auth state changes
```

### Check if Authenticated
```dart
final isAuthenticated = ref.watch(isAuthenticatedProvider);
// Provider<bool> - true if user is logged in
```

### Get Current User Profile
```dart
final userProfile = ref.watch(currentUserProfileProvider);
// StreamProvider<UserProfile?> - real-time updates
```

### Update User Profile
```dart
final updatedProfile = await ref.read(
  updateUserProfileProvider(
    UpdateProfileParams(
      displayName: 'New Name',
      phoneNumber: '+1234567890',
    ),
  ).future,
);
```

### Sign Out
```dart
await ref.read(signOutProvider.future);
// Clears all local data and authentication
```

---

## 🛍️ Product & Shopping Usage

### Get All Products
```dart
final products = ref.watch(allProductsProvider);
// StreamProvider<List<Product>> - real-time updates
// Pagination: 20 products per page
```

### Get Products by Category
```dart
final categoryProducts = ref.watch(
  productsByCategoryProvider('electronics'),
);
// StreamProvider<List<Product>>
```

### Search Products
```dart
final searchResults = ref.watch(
  searchProductsProvider('smartphone'),
);
// FutureProvider<List<Product>>
```

### Get Single Product
```dart
final product = ref.watch(productProvider('product123'));
// FutureProvider<Product>
```

### Filter Products
```dart
final filtered = ref.watch(
  filteredProductsProvider(
    FilterParams(
      category: 'electronics',
      minPrice: 100,
      maxPrice: 500,
      sortBy: 'price', // or 'rating', 'newest'
      searchQuery: 'phone',
    ),
  ),
);
// StreamProvider<List<Product>>
```

---

## 🛒 Shopping Cart Usage

### Get User's Cart
```dart
final cart = ref.watch(userCartProvider);
// StreamProvider<UserCart?> - real-time updates
```

### Watch Cart Total
```dart
final total = ref.watch(cartTotalProvider);
// Provider<double> - calculated from cart items
```

### Watch Item Count
```dart
final count = ref.watch(cartItemCountProvider);
// Provider<int> - total items in cart
```

### Add to Cart
```dart
await ref.read(
  addToCartProvider(
    AddToCartParams(
      productId: 'product123',
      quantity: 2,
      selectedOptions: {'color': 'red', 'size': 'M'},
    ),
  ),
);
// If product already in cart, increases quantity
```

### Update Cart Item Quantity
```dart
await ref.read(
  updateCartItemQuantityProvider(
    UpdateCartItemParams(
      productId: 'product123',
      quantity: 5,
    ),
  ),
);
```

### Remove from Cart
```dart
await ref.read(
  removeFromCartProvider('product123'),
);
```

### Clear Cart
```dart
await ref.read(clearCartProvider.future);
// Removes all items from cart
```

---

## 📦 Orders Usage

### Get User's Orders
```dart
final orders = ref.watch(userOrdersProvider);
// StreamProvider<List<Order>> - real-time updates
```

### Get Order Details
```dart
final order = ref.watch(orderDetailsProvider('order123'));
// FutureProvider<Order>
```

### Create Order
```dart
final order = await ref.read(
  createOrderProvider(
    CreateOrderParams(
      items: cartItems,
      shippingAddress: address,
      paymentMethod: 'credit_card',
    ),
  ).future,
);
// Returns: Order object with ID and status
```

### Watch Order Status Updates
```dart
final order = ref.watch(orderDetailsProvider('order123'));
// Automatically updates when status changes in Firestore
```

---

## ❤️ Favorites/Wishlist Usage

### Get User's Favorites
```dart
final favorites = ref.watch(userFavoritesProvider);
// StreamProvider<UserFavorites?> - real-time updates
```

### Check if Product is Favorited
```dart
final isFavorited = ref.watch(
  isProductFavoritedProvider('product123'),
);
// Provider<bool>
```

### Add to Favorites
```dart
await ref.read(
  addToFavoritesProvider('product123'),
);
```

### Remove from Favorites
```dart
await ref.read(
  removeFromFavoritesProvider('product123'),
);
```

---

## ⭐ Reviews Usage

### Get Product Reviews
```dart
final reviews = ref.watch(
  productReviewsProvider('product123'),
);
// StreamProvider<List<Review>> - real-time updates
```

### Add Review
```dart
final review = await ref.read(
  addReviewProvider(
    AddReviewParams(
      productId: 'product123',
      rating: 4.5,
      title: 'Great product!',
      content: 'Works as described',
      imageUrls: ['image_url_1', 'image_url_2'],
    ),
  ).future,
);
// Automatically updates product rating
```

---

## 📡 Offline Sync Usage

### Queue Operation While Offline
```dart
final syncService = OfflineSyncService.instance;

await syncService.queueOperation(
  collectionPath: 'users/userId/cart',
  documentId: 'cartDoc',
  data: {
    'items': [...],
    'timestamp': Timestamp.now(),
  },
  operation: SyncOperationType.update,
);
// Operation stored in Hive, synced when online
```

### Manually Trigger Sync
```dart
final result = await syncService.syncAllOperations();
// Returns SyncResult with count and status
```

### Check Pending Operations
```dart
final pending = await syncService.getQueuedOperations();
// Returns list of queued operations not yet synced
```

### Check Conflicts
```dart
final conflicts = await syncService.getPendingConflicts();
// Returns list of operations with sync conflicts
```

### Resolve Conflict
```dart
await syncService.resolveConflict(
  operationId: 'op123',
  resolution: ConflictResolution.useLocal, // or useRemote
);
```

---

## 🔍 Error Handling

### Authentication Errors
```dart
try {
  await ref.read(signInProvider(params).future);
} on AuthenticationException catch (e) {
  // Handle specific auth errors
  switch (e.code) {
    case 'invalid-email':
      print('Invalid email format');
    case 'user-not-found':
      print('User does not exist');
    case 'wrong-password':
      print('Incorrect password');
    case 'too-many-requests':
      print('Too many login attempts. Try again later');
    default:
      print('Authentication error: ${e.message}');
  }
}
```

### Firestore Errors
```dart
try {
  final products = await ref.read(allProductsProvider.future);
} on FirestoreException catch (e) {
  // Handle Firestore errors
  print('Firestore error: ${e.message}');
  print('Code: ${e.code}');
}
```

### Sync Errors
```dart
final result = await syncService.syncAllOperations();
if (result.status == SyncOperationResult.failure) {
  print('Sync failed: ${result.errors}');
}
if (result.status == SyncOperationResult.conflict) {
  print('Conflicts detected: ${result.conflictCount}');
}
```

---

## 🧪 Testing Examples

### Test User Registration
```dart
test('User can register with email and password', () async {
  final authService = AuthService.instance;
  
  final user = await authService.registerWithEmailAndPassword(
    email: 'test@example.com',
    password: 'TestPassword123!',
  );
  
  expect(user.email, 'test@example.com');
  expect(user.emailVerified, false);
});
```

### Test Product Search
```dart
test('Can search products', () async {
  final firestoreService = FirestoreService.instance;
  
  final results = await firestoreService.searchProducts('phone');
  
  expect(results, isNotEmpty);
  expect(results.every((p) => p.name.contains('phone')), true);
});
```

### Test Offline Sync
```dart
test('Operations queued while offline', () async {
  final syncService = OfflineSyncService.instance;
  
  await syncService.queueOperation(
    collectionPath: 'test',
    documentId: 'test1',
    data: {'test': true},
    operation: SyncOperationType.create,
  );
  
  final pending = await syncService.getQueuedOperations();
  expect(pending.length, greaterThan(0));
});
```

---

## ⚙️ Configuration

### Change Environment
```dart
// In firebase_config.dart
FirebaseConfig.environment = Environment.production;
// Options: Environment.development, staging, production
```

### Disable Analytics
```dart
// In firebase_config.dart
FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
```

### Set Logging Level
```dart
// In firebase_config.dart
FirebaseConfig.logLevel = FirebaseLogLevel.debug; // or info, warning, error
```

---

## 📊 Firestore Collections Structure

```
users/
  {userId}/
    ├── userProfile (UserProfile)
    ├── cart/ → UserCart document
    ├── favorites/ → UserFavorites document
    └── addresses/ (subcollection)

products/
  {productId}/
    └── reviews/ (subcollection - Review items)

orders/
  {userId}/
    {orderId} (Order document)

reviews/
  {reviewId} (Review document)

categories/
  {categoryId} (Category document)
```

---

## 🚨 Common Issues & Solutions

### Issue: "User not authenticated"
```dart
// Ensure user is logged in before accessing user-specific data
final isAuth = ref.watch(isAuthenticatedProvider);
if (isAuth.value ?? false) {
  // Safe to access user data
} else {
  // Show login screen
}
```

### Issue: "Firestore permission denied"
```dart
// Check:
// 1. Firestore rules deployed: firebase deploy --only firestore:rules
// 2. User is authenticated
// 3. Collection paths match rules (users/{userId}, etc)
```

### Issue: "Offline operations not syncing"
```dart
// Check:
// 1. OfflineSyncService initialized in main.dart
// 2. Hive box properly initialized
// 3. Connectivity restored (check Connectivity().onConnectivityChanged)
```

### Issue: "Images not loading from storage"
```dart
// Check:
// 1. Storage bucket name in firebase_options.dart
// 2. Storage rules allow public read access
// 3. Image URLs are valid download URLs
// 4. Network connectivity is stable
```

---

## 📚 Related Files

- **Services**: `lib/services/`
  - `auth_service.dart` - Authentication
  - `firestore_service.dart` - Database
  - `offline_sync_service.dart` - Offline sync

- **Providers**: `lib/providers/`
  - `auth_provider.dart` - Auth state management
  - `product_provider.dart` - Shopping state management

- **Models**: `lib/models/firestore_models.dart`

- **Configuration**: `lib/config/`
  - `firebase_config.dart` - Initialization
  - `firebase_options.dart` - Credentials

---

## 🔗 External Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Riverpod](https://riverpod.dev)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

---

**For more detailed information, see:**
- SPRINT_2_README.md
- SPRINT_2_FIREBASE_INTEGRATION_GUIDE.md
- Inline code documentation in service files

Generated: December 16, 2025
