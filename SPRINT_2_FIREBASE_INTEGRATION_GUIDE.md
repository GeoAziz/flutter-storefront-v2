# Firebase Integration - Sprint 2 Implementation Guide

## Overview

This document provides step-by-step implementation guidance for integrating Firebase into the Flutter E-commerce application. All core services, models, and providers have been implemented and are ready for integration testing and refinement.

## What Has Been Implemented

### 1. **Firebase Configuration** (`lib/config/firebase_config.dart`)
- Multi-environment support (development, staging, production)
- Firestore settings optimization for Spark Plan
- Firebase Auth, Firestore, Storage, Messaging initialization
- Automatic FCM token retrieval
- Centralized configuration management

### 2. **Data Models** (`lib/models/firestore_models.dart`)
- **UserProfile**: User account data, preferences, addresses
- **Product**: E-commerce product catalog with ratings
- **CartItem & UserCart**: Shopping cart management
- **Order & OrderItem**: Order tracking with status history
- **Review**: Product reviews and ratings
- **UserFavorites**: Wishlist management

All models include:
- Serialization/Deserialization (toMap/fromMap)
- Timestamp conversion from Firestore
- copyWith methods for immutability

### 3. **Authentication Service** (`lib/services/auth_service.dart`)
- Email/password registration and login
- Anonymous authentication
- Password reset and update
- Email verification
- User profile management
- Account deletion with data cleanup
- Comprehensive error handling with user-friendly messages

### 4. **Firestore Service** (`lib/services/firestore_service.dart`)
- **Products**: Browse, search, filter, real-time streaming
- **Cart**: CRUD operations with real-time sync
- **Orders**: Create, track, update status
- **Favorites**: Add/remove favorites with streaming
- **Reviews**: Product reviews with automatic rating updates
- Batch write and transaction support

### 5. **Firestore Security Rules** (`lib/config/firestore.rules`)
- User-specific data access control
- Role-based admin access
- Rate limiting (5 writes per minute per user)
- Public product catalog read access
- Subcollections for addresses, payment methods, order history

### 6. **Riverpod Providers** 
#### Auth Providers (`lib/providers/auth_provider.dart`)
- Auth state stream
- Current user ID and profile
- Sign up, sign in, anonymous login
- Password management
- Email verification
- Account deletion

#### Product & Cart Providers (`lib/providers/product_provider.dart`)
- All products stream
- Products by category
- Search functionality
- Filtered products
- Cart management (add, remove, update, clear)
- Order tracking
- Favorites management
- Product reviews

### 7. **Updated Dependencies** (`pubspec.yaml`)
- Firebase Core, Auth, Firestore, Storage, Messaging
- Local storage: SQLite, Hive, Shared Preferences
- Networking: HTTP, Dio
- Error tracking: Sentry Flutter
- Testing: Mockito, Firebase Emulator

## Setup Instructions

### Step 1: Firebase Project Creation

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (or use existing)
3. Enable the following:
   - **Firestore Database** (Spark Plan)
   - **Authentication** (Email/Password, Google Sign-In)
   - **Cloud Storage** (for images)
   - **Cloud Messaging** (for notifications)
   - **Analytics** (optional but recommended)

### Step 2: Configure `firebase_options.dart`

Update `lib/config/firebase_options.dart` with your Firebase project credentials:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_PROJECT_NUMBER',
  projectId: 'your-firebase-project-id',
  storageBucket: 'your-firebase-project-id.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: '1:YOUR_PROJECT_NUMBER:ios:YOUR_IOS_APP_ID',
  messagingSenderId: 'YOUR_PROJECT_NUMBER',
  projectId: 'your-firebase-project-id',
  storageBucket: 'your-firebase-project-id.appspot.com',
  iosBundleId: 'com.example.shop',
);
```

### Step 3: Android Configuration

1. **Download `google-services.json`** from Firebase Console
2. **Place it in** `android/app/google-services.json`
3. **Update** `android/build.gradle`:
   ```gradle
   classpath 'com.google.gms:google-services:4.3.15'
   ```
4. **Update** `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   
   android {
     compileSdkVersion 34
     defaultConfig {
       minSdkVersion 21
     }
   }
   ```

### Step 4: iOS Configuration

1. **Download** `GoogleService-Info.plist` from Firebase Console
2. **Add to Xcode**:
   - Open `ios/Runner.xcodeproj` in Xcode
   - Drag `GoogleService-Info.plist` into the project
   - Select "Copy if needed"
   - Add to "Runner" target

3. **Update** `ios/Podfile`:
   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       target.build_configurations.each do |config|
         config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
           '$(inherited)',
           'FIREBASE_ANALYTICS_COLLECTION_ENABLED=1',
         ]
       end
     end
   end
   ```

### Step 5: Deploy Firestore Security Rules

1. **Install Firebase CLI** (if not already):
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Initialize Firebase in project directory**:
   ```bash
   firebase init
   ```

3. **Copy security rules** from `lib/config/firestore.rules` to `firestore.rules`

4. **Deploy rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Step 6: Setup Firestore Indexes

Create the following composite indexes in Firebase Console or deploy via `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "active", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "active", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### Step 7: Get Dependencies

```bash
flutter pub get
```

## Testing & Validation

### 1. Local Testing with Emulator

```bash
# Start Firebase Emulator Suite
firebase emulators:start

# Set environment variable to use emulator
export FIREBASE_EMULATOR_HOST=localhost:8080
```

### 2. Run Unit Tests

```bash
flutter test
```

### 3. Test Authentication

Create test in `test/auth_service_test.dart`:

```dart
void main() {
  test('Sign up with email creates user account', () async {
    final profile = await authService.registerWithEmailAndPassword(
      email: 'test@example.com',
      password: 'Test@1234',
      displayName: 'Test User',
    );

    expect(profile.email, 'test@example.com');
    expect(profile.displayName, 'Test User');
  });
}
```

### 4. Test Firestore Operations

Create test in `test/firestore_service_test.dart`:

```dart
void main() {
  test('Fetch products successfully', () async {
    final products = await firestoreService.getAllProducts();
    expect(products, isNotEmpty);
  });

  test('Add item to cart', () async {
    final cart = models.UserCart(
      userId: 'test-user',
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await firestoreService.updateCart(cart);
    final retrieved = await firestoreService.getUserCart('test-user');
    expect(retrieved, isNotNull);
  });
}
```

## Integration Checklist

- [ ] Firebase project created and configured
- [ ] `firebase_options.dart` updated with credentials
- [ ] Android configuration complete
- [ ] iOS configuration complete
- [ ] Firestore security rules deployed
- [ ] Firestore indexes created
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Authentication service tested
- [ ] Firestore operations tested
- [ ] Riverpod providers integrated into UI
- [ ] Real-time listeners working
- [ ] Error handling tested
- [ ] Offline persistence enabled
- [ ] Performance monitoring active

## Optimization for Spark Plan

### Cost-Saving Strategies Implemented

1. **Minimal Cache Size**: 10MB for production (configurable)
2. **Rate Limiting**: 5 writes per minute per user via security rules
3. **Efficient Queries**: 
   - Indexed queries for fast retrieval
   - Pagination support to reduce data transfer
   - Stream listeners for real-time updates
4. **Selective Data Fetching**: Only request needed fields
5. **Batch Operations**: Batch writes to reduce operation count

### Monitoring Costs

Use Firebase Console to monitor:
- Firestore read/write operations
- Storage usage
- Cloud Messaging message count
- Data transfer

## Next Steps

1. **Integrate UI Components**: Update existing screens to use providers
2. **Implement Product Listing**: Create product list screen with real-time updates
3. **Build Shopping Cart**: Add to cart, checkout flow
4. **Setup Checkout**: Order creation and payment integration
5. **Order Tracking**: User order history and status tracking
6. **Push Notifications**: FCM integration for order updates
7. **Analytics**: Track user behavior and sales metrics

## Troubleshooting

### Firebase Initialization Error
- Verify `firebase_options.dart` credentials
- Ensure Google services JSON/plist files are in correct locations
- Check Android minimum SDK version (21+)

### Firestore Permission Denied
- Verify security rules are deployed correctly
- Check user authentication status
- Review rule conditions in Firebase Console

### Real-Time Listener Not Updating
- Verify listener is properly subscribed in provider
- Check Firestore read permissions
- Ensure document exists in collection

### Slow Firestore Queries
- Create required indexes (check console for suggestions)
- Optimize query filters
- Consider pagination for large datasets

## Performance Tips

1. **Use Pagination**: Load products in batches of 20-50
2. **Implement Caching**: Use `hive` for local caching
3. **Batch Updates**: Group multiple writes together
4. **Compress Images**: Optimize product images before upload
5. **Use Transactions**: For operations requiring consistency
6. **Monitor Analytics**: Track performance metrics

## Security Best Practices

1. **Never commit credentials**: Use environment variables
2. **Validate on Server**: Security rules enforce validation
3. **Rate Limiting**: Implemented in security rules
4. **User Authentication**: Required for sensitive operations
5. **Data Encryption**: Firebase handles in transit
6. **Regular Backups**: Enable Firestore backups

## Documentation References

- [Firebase Docs](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Flutter Fire](https://firebase.flutter.dev/)
- [Riverpod Docs](https://riverpod.dev/)

---

**Last Updated**: December 16, 2025
**Version**: Sprint 2 Implementation v1.0
**Status**: Ready for Integration Testing
