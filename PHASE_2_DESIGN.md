# Phase 2 — Product Seeding + Real Orders (Kickoff)

## Overview

Phase 2 builds on the proven Firebase Auth + Firestore foundation from Phase 1. The goals are:

1. **Product Seeding**: Create test product data and load it into Firestore
2. **Real Order Flows**: Design and implement order models, repositories, and UI flows
3. **Payment Integration**: Mock or integrate a payment provider (TBD)

By end of Phase 2, the app will support a complete e-commerce flow: browse products → add to cart → checkout → place order → view order history.

## High-Level Architecture

### Data Models

#### Product
```dart
class Product {
  final String id;           // Firestore doc ID
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final double rating;       // 0-5
  final int reviewCount;
  final DateTime createdAt;
}
```

#### Order
```dart
class Order {
  final String id;           // Firestore doc ID
  final String userId;       // users/{uid}
  final List<OrderItem> items;
  final double totalPrice;
  final String status;       // 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  final String? paymentMethod;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime? completedAt;
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;        // Price at time of order
  final int quantity;
}
```

#### Cart (already exists in Riverpod, enhance if needed)
```dart
class CartItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
}
```

### Firestore Collections

```
firestore
  ├── products/          # Public read, no auth required
  │   ├── {productId}
  │   │   ├── name
  │   │   ├── price
  │   │   ├── imageUrl
  │   │   ├── category
  │   │   ├── stock
  │   │   ├── rating
  │   │   ├── reviewCount
  │   │   └── createdAt
  │
  ├── users/             # Owned by uid (Phase 1)
  │   ├── {userId}
  │   │   ├── uid
  │   │   ├── email
  │   │   ├── role
  │   │   └── createdAt
  │
  ├── orders/            # Owned by uid, scoped in rules
  │   ├── {orderId}
  │   │   ├── userId
  │   │   ├── items[]
  │   │   ├── totalPrice
  │   │   ├── status
  │   │   ├── paymentMethod
  │   │   ├── trackingNumber
  │   │   ├── createdAt
  │   │   └── completedAt
```

### Security Rules (Firestore)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Products: Public read
    match /products/{document=**} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Users: Owned by uid
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Orders: Owned by uid
    match /orders/{orderId} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }

    // Helper functions
    function isAdmin() {
      return request.auth.uid != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Implementation Plan

### Phase 2.1: Product Model + Repository

**Files to create:**
- `lib/models/product.dart` — Product model (immutable, with `.fromFirestore()`, `.toFirestore()`)
- `lib/repositories/product_repository.dart` — ProductRepository with methods:
  - `getAllProducts()` → Stream<List<Product>>
  - `getProductById(id)` → Future<Product>
  - `searchProducts(query, category)` → Future<List<Product>>
  - `getProductsByCategory(category)` → Stream<List<Product>>

**Firestore structure:**
- Collection: `products`
- Document: `{productId}` (auto-generated or custom)
- Fields: name, price, description, imageUrl, category, stock, rating, reviewCount, createdAt

**Seeding:**
- Create `scripts/seed_products.dart` — Dart script that populates Firestore with sample products
  - Uses `firebase_app_rest` or HTTP client to hit Firestore REST API
  - Includes ~20-50 sample products across categories (electronics, fashion, etc.)
  - Create `data/seed_products.json` with product data
  - Runner script: `scripts/run_seed_products.sh`

**Testing:**
- Unit test for ProductRepository using a fake Firestore (or REST mock)
- Widget test: ProductListScreen displays fetched products

### Phase 2.2: Order Model + Repository

**Files to create:**
- `lib/models/order.dart` — Order and OrderItem models
- `lib/repositories/order_repository.dart` — OrderRepository with methods:
  - `placeOrder(userId, cartItems, paymentMethod)` → Future<String> (orderId)
  - `getOrderById(userId, orderId)` → Future<Order>
  - `getOrdersByUser(userId)` → Stream<List<Order>>
  - `updateOrderStatus(orderId, status)` → Future<void>
  - `cancelOrder(orderId)` → Future<void>

**Firestore structure:**
- Collection: `orders`
- Document: `{orderId}` (auto-generated)
- Fields: userId, items[], totalPrice, status, paymentMethod, trackingNumber, createdAt, completedAt
- Security rule: Only creator (userId) can read/write their orders

**Update Firestore rules** to include orders collection with uid-scoped access.

### Phase 2.3: Cart → Order Flow

**Enhance CartScreen:**
- Add "Checkout" button
- Validate cart (not empty, stock available)
- Transition to CheckoutScreen

**Create CheckoutScreen:**
- Display cart summary (items, total)
- Payment method selector (mock cards or payment provider)
- Place order button
- On success: navigate to OrderConfirmationScreen, clear cart, update user's order list

**Update providers:**
- Create `orderProvider` (Riverpod) that watches the current user's orders
- Enhance `cartProvider` to use ProductRepository (watch product details for each item)
- Add `placeOrderProvider` (async) that calls OrderRepository.placeOrder()

### Phase 2.4: Order History & Details

**Create OrderHistoryScreen:**
- List user's orders (from orderProvider)
- Tap to view OrderDetailsScreen

**Create OrderDetailsScreen:**
- Display order summary: items, total, status, dates
- Show tracking info if shipped
- Option to cancel order (if status allows)

### Phase 2.5: Payment Integration (Mock)

For Phase 2, implement a **mock payment provider**:

```dart
class MockPaymentProvider {
  Future<PaymentResult> processPayment({
    required String cardLast4,
    required double amount,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));
    
    // 95% success rate for demo
    if (Random().nextDouble() < 0.95) {
      return PaymentResult(
        success: true,
        transactionId: 'txn_${uuid.v4()}',
      );
    } else {
      return PaymentResult(
        success: false,
        error: 'Card declined',
      );
    }
  }
}
```

Later, this can be replaced with Stripe, PayPal, or another provider.

## Execution Timeline

### Day 1: Product Model + Seeding
- [ ] Create Product model
- [ ] Create ProductRepository + providers
- [ ] Create seed_products.dart + runner script
- [ ] Seed ~30 test products to local Firestore emulator
- [ ] Test: ProductRepository.getAllProducts() returns products

### Day 2: Product UI + Discovery
- [ ] Connect existing product list screens to ProductRepository
- [ ] Add search/filter by category
- [ ] Add product details screen with real data
- [ ] Test: Screens fetch and display products

### Day 3: Order Model + Repository
- [ ] Create Order model
- [ ] Create OrderRepository + providers
- [ ] Update Firestore rules to include orders collection
- [ ] Test: placeOrder() creates doc in Firestore with correct userId scope

### Day 4: Checkout Flow
- [ ] Create CheckoutScreen + MockPaymentProvider
- [ ] Update CartScreen with "Checkout" button
- [ ] Implement placeOrder() flow: cart → order creation → navigate to confirmation
- [ ] Test: End-to-end checkout (cart → payment mock → order created)

### Day 5: Order History + Polish
- [ ] Create OrderHistoryScreen + OrderDetailsScreen
- [ ] Add cancel order functionality
- [ ] Polish error handling and UI feedback
- [ ] Add to CI: test product seeding + order flows

### (Optional) Phase 2.5: Payment Provider
- Integrate Stripe / PayPal / other provider
- Replace MockPaymentProvider with real integration
- Handle webhook / callback for payment status

## Testing Strategy

### Headless Harness (Extend)
- Extend `scripts/auth_harness.dart` to validate product seed and order creation via REST
- Verify products collection is readable
- Verify orders collection is uid-scoped

### Unit Tests
- ProductRepository.getAllProducts() with fake Firestore
- OrderRepository.placeOrder() with mocked dependencies
- PaymentProvider mock behavior

### Widget Tests (Mocked)
- ProductListScreen renders products from repository
- CheckoutScreen validates cart and calls placeOrder()
- OrderHistoryScreen displays user's orders

### Integration Tests (Device/Emulator)
- End-to-end: Browse products → Add to cart → Checkout → Order confirmation
- Nightly CI run on Android emulator

## Files to Create / Modify

**New files:**
- `lib/models/product.dart`
- `lib/models/order.dart`
- `lib/repositories/product_repository.dart`
- `lib/repositories/order_repository.dart`
- `lib/providers/product_provider.dart`
- `lib/providers/order_provider.dart`
- `lib/screens/checkout/checkout_screen.dart`
- `lib/screens/order_history/order_history_screen.dart`
- `lib/screens/order_history/order_details_screen.dart`
- `lib/services/payment_provider.dart` (mock)
- `scripts/seed_products.dart`
- `scripts/run_seed_products.sh`
- `data/seed_products.json`
- `test/repositories/product_repository_test.dart`
- `test/repositories/order_repository_test.dart`

**Modify:**
- `lib/config/firestore.rules` — Add orders collection rules
- `lib/screens/cart/cart_screen.dart` — Add "Checkout" button
- `.github/workflows/ci.yml` — Add seed products + order flow tests
- Existing providers to watch ProductRepository

## Success Criteria

- [ ] 30+ products seeded in Firestore (via script or manual import)
- [ ] ProductRepository fetches and filters products
- [ ] Product screens display real data
- [ ] Checkout flow: cart → order creation → confirmation
- [ ] Order history screen shows user's orders
- [ ] Security rules enforce per-user access to orders
- [ ] Headless harness validates product seed and order creation
- [ ] Mocked tests validate checkout UI and payment flow
- [ ] Integration tests validate full user journey

## Next Steps

1. **Validate Option B locally** (5 min): Run mocked tests, confirm both pass.
2. **Push to main**: Trigger CI, confirm headless harness + mocked tests pass.
3. **Start Phase 2.1**: Create Product model and ProductRepository.
4. **Parallelize**: UI team starts product screens while data team works on seeding.

**You're cleared to begin Phase 2 immediately. No blockers.**
