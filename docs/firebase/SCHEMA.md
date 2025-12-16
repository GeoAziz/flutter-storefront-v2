# Firestore Schema (Sprint 1)

This document proposes a minimal schema for Sprint 1 focusing on products, categories, users, wishlists, and comparisons.

Collections & Documents

1. products (collection)
   - documentId: productId (string)
   - fields:
     - title: string
     - description: string
     - price: double
     - priceAfetDiscount: double (nullable)
     - dicountpercent: int (nullable)
     - image: string (storage path or public URL)
     - thumbnail: string (storage path or public URL)
     - brandName: string
     - rating: double
     - reviewCount: int
     - createdAt: timestamp
     - updatedAt: timestamp
     - tags: array<string>
     - categoryId: string

2. categories (collection)
   - documentId: categoryId
   - fields:
     - name: string
     - slug: string
     - parentId: string (nullable)

3. users (collection)
   - documentId: uid (firebase auth id)
   - fields:
     - displayName: string
     - email: string
     - createdAt: timestamp
     - preferences: map

4. wishlists (collection)
   - documentId: uid (user id)
   - subcollection: items (or field 'productIds' array)
   - item fields (if subcollection):
     - productId: string
     - addedAt: timestamp

5. comparisons (collection)
   - documentId: uid
   - fields:
     - productIds: array<string>
     - updatedAt: timestamp

Indexes
- products.createdAt (descending) — for pagination
- products.categoryId + createdAt — composite index for category listing
- products.tags array-contains — for tag filtering (create composite if needed)

Security Rules (placeholder)
- Allow read: true for products public data
- Allow write: Authenticated users only for wishlists/comparisons

Example rules (review before production)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /products/{product} {
      allow read: if true;
      allow write: if false; // admin-only via server
    }

    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /wishlists/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /comparisons/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Notes
- For Sprint 1 we will seed the emulator with product documents and thumbnails. Thumbnails help save memory and bandwidth in the app.
- In Phase 7 we will add admin tools for uploading products and resizing images (Cloud Functions or CDN).

Sync examples
----------------
For Sprint 1 repositories there are helper methods that perform best-effort syncs to Firestore:

```dart
// sync wishlist for current user
await wishlistRepository.syncToFirestore(uid);

// sync comparison list
await comparisonRepository.syncToFirestore(uid);
```

These methods are non-blocking (they catch and log errors) to avoid impacting local UX. They are intended to be used when the app detects connectivity and an authenticated user.
