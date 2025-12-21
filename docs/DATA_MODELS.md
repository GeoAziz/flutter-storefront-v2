# Data Models - Flutter Storefront V2

This document describes the Firestore collection schemas and data models used in the application.

## Collection Overview

The application uses the following Firestore collections:

| Collection | Purpose | Document ID Pattern |
|------------|---------|-------------------|
| `categories` | Product categories | `{category-slug}` |
| `products` | Product catalog | `{PRODUCT-ID}` |
| `inventory` | Stock tracking | `{productId}` |
| `users` | User accounts | `{uid}` |
| `appConfig` | App configuration | `homeScreen`, etc. |

## Categories Collection

**Path:** `/categories/{categoryId}`

Product categories for organizing the catalog.

### Schema

```typescript
{
  id: string;                    // Unique category identifier (e.g., "electronics-phones")
  name: string;                  // Display name (e.g., "Phones & Tablets")
  slug: string;                  // URL-friendly identifier
  description: string;           // Category description
  icon: string;                  // Material icon name
  imageUrl: string;              // Category banner image URL
  active: boolean;               // Whether category is active
  featured: boolean;             // Show in featured sections
  order: number;                 // Display order (1-based)
  productCount: number;          // Number of products in category
  metadata: {
    color: string;               // Category theme color (hex)
    showInMenu: boolean;         // Show in navigation menu
    showInHome: boolean;         // Show on home screen
  };
  createdAt: string;             // ISO 8601 timestamp
  updatedAt: string;             // ISO 8601 timestamp
}
```

### Example

```json
{
  "id": "electronics-phones",
  "name": "Phones & Tablets",
  "slug": "electronics-phones",
  "description": "Smartphones, feature phones, and tablets",
  "icon": "phone_android",
  "imageUrl": "https://storage.googleapis.com/.../phones.jpg",
  "active": true,
  "featured": true,
  "order": 1,
  "productCount": 8,
  "metadata": {
    "color": "#2196F3",
    "showInMenu": true,
    "showInHome": true
  },
  "createdAt": "2024-03-20T10:00:00Z",
  "updatedAt": "2024-03-20T10:00:00Z"
}
```

### Indexes

- `active` (ascending)
- `featured` (ascending)
- `order` (ascending)

## Products Collection

**Path:** `/products/{productId}`

Complete product catalog with variants, pricing, and metadata.

### Schema

```typescript
{
  id: string;                          // Unique product identifier
  sku: string;                         // Stock Keeping Unit
  title: string;                       // Product name
  description: string;                 // Product description
  price: number;                       // Base price (in minor units, e.g., cents)
  currency: string;                    // Currency code (ISO 4217)
  categoryId: string;                  // Reference to category
  imageUrl: string;                    // Main product image
  thumbnail?: string;                  // Thumbnail image
  stock: number;                       // Total stock quantity
  active: boolean;                     // Product is active/visible
  createdAt: string;                   // ISO 8601 timestamp
  updatedAt: string;                   // ISO 8601 timestamp
  
  // Optional fields
  vendorId?: string;                   // Vendor/supplier identifier
  costPrice?: number;                  // Wholesale/cost price
  priceAfterDiscount?: number;         // Discounted price
  discountPercent?: number;            // Discount percentage
  weight?: number;                     // Weight in grams
  dimensions?: {
    length: number;                    // Length in cm
    width: number;                     // Width in cm
    height: number;                    // Height in cm
  };
  stockByLocation?: {
    [warehouseId: string]: number;     // Stock per warehouse
  };
  backorderAllowed?: boolean;          // Allow backorders
  tags?: string[];                     // Search/filter tags
  rating?: number;                     // Average rating (0-5)
  reviewCount?: number;                // Number of reviews
  featured?: boolean;                  // Featured product
  slug?: string;                       // URL-friendly identifier
  relatedProductIds?: string[];        // Related product IDs
  searchTerms?: string[];              // Auto-generated search terms
  
  metadata?: {
    warrantyMonths?: number;           // Warranty period
    localWarranty?: boolean;           // Local warranty available
    importDutyPaid?: boolean;          // Import duty status
  };
  
  attributes?: {
    [key: string]: string[];           // Product attributes (color, size, etc.)
  };
  
  variants?: Array<{
    id: string;                        // Variant identifier
    sku: string;                       // Variant SKU
    attributes: {
      [key: string]: string;           // Variant-specific attributes
    };
    price: number;                     // Variant price
    stock: number;                     // Variant stock
    imageUrl?: string;                 // Variant image
  }>;
}
```

### Example

```json
{
  "id": "TECNO-SPARK-20-PRO",
  "sku": "TPRO20-256-BLK",
  "title": "Tecno Spark 20 Pro",
  "description": "6.78\" FHD+ display, 256GB storage",
  "price": 28999,
  "currency": "KES",
  "categoryId": "electronics-phones",
  "imageUrl": "https://.../tecno-spark20-pro-main.jpg",
  "stock": 47,
  "active": true,
  "rating": 4.3,
  "reviewCount": 124,
  "featured": true,
  "tags": ["smartphone", "android", "tecno"],
  "searchTerms": ["tecno", "spark", "pro", "smartphone", "android"],
  "variants": [
    {
      "id": "TECNO-SPARK-20-PRO-BLUE-128",
      "sku": "TPRO20-128-BLU",
      "attributes": {
        "color": "Crystal Blue",
        "storage": "128GB"
      },
      "price": 25999,
      "stock": 22
    }
  ]
}
```

### Indexes

- `categoryId` (ascending)
- `active` (ascending)
- `featured` (ascending)
- `price` (ascending)
- Array index on `tags`
- Array index on `searchTerms`

## Inventory Collection

**Path:** `/inventory/{productId}`

Stock tracking and warehouse management for products.

### Schema

```typescript
{
  productId: string;                   // Reference to product
  sku: string;                         // Product SKU
  stock: number;                       // Total available stock
  reserved: number;                    // Reserved stock (in carts/orders)
  lowStockThreshold: number;           // Low stock alert threshold
  reorderLevel: number;                // Reorder point
  supplierLeadTimeDays: number;        // Supplier lead time
  lastRestocked: string;               // Last restock date (ISO 8601)
  cost: number;                        // Unit cost price
  
  locations: {
    [warehouseId: string]: {
      stock: number;                   // Stock at location
      reserved: number;                // Reserved at location
      aisle?: string;                  // Warehouse aisle
      shelf?: string;                  // Shelf number
    };
  };
  
  status: string;                      // "in_stock" | "low_stock" | "out_of_stock"
  trackInventory: boolean;             // Enable inventory tracking
  restockETA?: string;                 // Expected restock date (ISO 8601)
  createdAt: string;                   // ISO 8601 timestamp
  updatedAt: string;                   // ISO 8601 timestamp
}
```

### Example

```json
{
  "productId": "TECNO-SPARK-20-PRO",
  "sku": "TPRO20-256-BLK",
  "stock": 47,
  "reserved": 5,
  "lowStockThreshold": 10,
  "reorderLevel": 20,
  "supplierLeadTimeDays": 14,
  "lastRestocked": "2024-03-18T10:00:00Z",
  "cost": 24500,
  "locations": {
    "nairobi-warehouse": {
      "stock": 32,
      "reserved": 3,
      "aisle": "A2",
      "shelf": "12"
    },
    "mombasa-warehouse": {
      "stock": 15,
      "reserved": 2,
      "aisle": "B1",
      "shelf": "08"
    }
  },
  "status": "in_stock",
  "trackInventory": true
}
```

### Indexes

- `status` (ascending)
- `stock` (ascending)

## Users Collection

**Path:** `/users/{uid}`

User accounts and profiles.

### Schema

```typescript
{
  uid: string;                         // Firebase Auth UID
  email: string;                       // User email
  displayName: string;                 // Display name
  phoneNumber?: string;                // Phone number (E.164 format)
  role: string;                        // "customer" | "admin" | "vendor"
  emailVerified: boolean;              // Email verification status
  active: boolean;                     // Account active status
  createdAt: string;                   // Account creation date (ISO 8601)
  
  preferences: {
    language: string;                  // Language code (e.g., "en")
    currency: string;                  // Preferred currency (ISO 4217)
    notifications: {
      email: boolean;                  // Email notifications enabled
      push: boolean;                   // Push notifications enabled
      sms: boolean;                    // SMS notifications enabled
    };
  };
  
  addresses: Array<{
    id: string;                        // Address identifier
    type: string;                      // "home" | "work" | "other"
    name: string;                      // Address label
    street: string;                    // Street address
    city: string;                      // City
    state: string;                     // State/province
    postalCode: string;                // Postal/ZIP code
    country: string;                   // Country
    phone: string;                     // Contact phone
    isDefault: boolean;                // Default address flag
  }>;
  
  updatedAt: string;                   // Last update (ISO 8601)
}
```

### Example

```json
{
  "uid": "test-user-001",
  "email": "testuser@example.com",
  "displayName": "John Mwangi",
  "phoneNumber": "+254712345678",
  "role": "customer",
  "emailVerified": true,
  "active": true,
  "createdAt": "2024-01-15T10:00:00Z",
  "preferences": {
    "language": "en",
    "currency": "KES",
    "notifications": {
      "email": true,
      "push": true,
      "sms": false
    }
  },
  "addresses": [
    {
      "id": "addr-001",
      "type": "home",
      "name": "Home",
      "street": "123 Kimathi Street",
      "city": "Nairobi",
      "state": "Nairobi County",
      "postalCode": "00100",
      "country": "Kenya",
      "phone": "+254712345678",
      "isDefault": true
    }
  ]
}
```

### Indexes

- `email` (ascending)
- `role` (ascending)

## App Config Collection

**Path:** `/appConfig/{configId}`

Application-wide configuration documents.

### Home Screen Config

**Document ID:** `homeScreen`

Dynamic home screen layout configuration.

#### Schema

```typescript
{
  sections: Array<{
    id: string;                        // Section identifier
    type: string;                      // Section type (see types below)
    title: string;                     // Section title
    subtitle?: string;                 // Section subtitle
    enabled: boolean;                  // Section enabled/visible
    order: number;                     // Display order
    data: object;                      // Type-specific data (see below)
  }>;
  createdAt: string;                   // ISO 8601 timestamp
  updatedAt: string;                   // ISO 8601 timestamp
}
```

#### Section Types

**Carousel Banner:**
```typescript
{
  type: "carousel",
  data: {
    banners: Array<{
      id: string;
      imageUrl: string;
      title: string;
      subtitle: string;
      actionType: "category" | "product" | "url";
      actionTarget: string;
      backgroundColor?: string;
    }>;
    autoplay: boolean;
    autoplayInterval: number;
    showIndicators: boolean;
  }
}
```

**Category Grid:**
```typescript
{
  type: "category_grid",
  data: {
    categoryIds: string[];
    columns: number;
    showProductCount: boolean;
  }
}
```

**Product List (Horizontal):**
```typescript
{
  type: "product_list_horizontal",
  data: {
    productIds: string[];
    showTimer?: boolean;
    timerEndDate?: string;
    backgroundColor?: string;
  }
}
```

**Product Grid:**
```typescript
{
  type: "product_grid",
  data: {
    productIds: string[];
    columns: number;
    showRating: boolean;
    showReviewCount?: boolean;
  }
}
```

**Category Section:**
```typescript
{
  type: "category_section",
  data: {
    categoryId: string;
    productIds: string[];
    layout: "horizontal_scroll" | "grid";
    showViewAllButton: boolean;
    backgroundColor?: string;
  }
}
```

## Data Relationships

```
categories
    ↓ (categoryId)
products → inventory (productId)
    ↓ (productIds)
homeScreen sections

users (independent)
```

## Field Validations

### Common Rules

- **IDs:** Alphanumeric with hyphens, uppercase for products
- **Slugs:** Lowercase alphanumeric with hyphens
- **Timestamps:** ISO 8601 format (YYYY-MM-DDTHH:mm:ssZ)
- **Currencies:** ISO 4217 codes (e.g., "KES", "USD")
- **Prices:** Integer values in minor units (cents/paise)

### Product-Specific

- `stock` >= 0
- `price` > 0
- `rating` between 0 and 5
- `discountPercent` between 0 and 100

### Inventory-Specific

- `stock` >= `reserved`
- `lowStockThreshold` < `reorderLevel`
- Status: "in_stock" when stock > lowStockThreshold
- Status: "low_stock" when stock <= lowStockThreshold && stock > 0
- Status: "out_of_stock" when stock == 0

## Security Rules

Recommended Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Categories - Read public, write admin
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if request.auth.token.role == 'admin';
    }
    
    // Products - Read public, write admin
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth.token.role == 'admin';
    }
    
    // Inventory - Read admin, write admin
    match /inventory/{productId} {
      allow read: if request.auth.token.role == 'admin';
      allow write: if request.auth.token.role == 'admin';
    }
    
    // Users - Read/write own, admin can read all
    match /users/{userId} {
      allow read: if request.auth.uid == userId || 
                     request.auth.token.role == 'admin';
      allow write: if request.auth.uid == userId;
    }
    
    // App Config - Read public, write admin
    match /appConfig/{configId} {
      allow read: if true;
      allow write: if request.auth.token.role == 'admin';
    }
  }
}
```

## Migration Guide

When updating data models:

1. Update seed files in `data/`
2. Update this documentation
3. Run seeder to update emulator
4. Test changes in app
5. Deploy to production Firestore
6. Update security rules if needed

## Related Documentation

- [Seeding Guide](./SEEDING_GUIDE.md) - How to populate data
- [README](../README.md) - Project overview
- [Firebase Setup](../FIREBASE_SETUP_QUICK_REFERENCE.md) - Firebase configuration
