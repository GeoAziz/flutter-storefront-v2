# Seeding Guide - Flutter Storefront V2

This guide explains how to use the unified seeder to populate your Firestore database with initial data.

## Overview

The unified seeder (`seed_firestore_complete.dart`) populates all Firestore collections in the correct dependency order:

1. **Categories** - Product categories
2. **Products** - Product catalog with search terms
3. **Inventory** - Stock tracking for key products
4. **Users** - Test user accounts
5. **Home Config** - Dynamic home screen configuration

## Prerequisites

- Firebase emulator running on port 8080 (default)
- Dart SDK or Flutter installed
- Data files in the `data/` directory

## Quick Start

### 1. Start Firebase Emulator

```bash
firebase emulators:start --only firestore
```

Or run in the background:

```bash
firebase emulators:start --only firestore &
```

### 2. Run the Seeder

Using the shell wrapper (recommended):

```bash
./scripts/run_complete_seed.sh
```

Or run directly with Dart:

```bash
dart scripts/seed_firestore_complete.dart --project=demo-project
```

## Configuration

### Environment Variables

- `FIREBASE_PROJECT` - Firebase project ID (default: `demo-project`)
- `EMULATOR_HOST` - Emulator host (default: `127.0.0.1`)
- `EMULATOR_PORT` - Emulator port (default: `8080`)

### Command Line Arguments

```bash
dart scripts/seed_firestore_complete.dart --project=my-project --host=localhost --port=8080
```

## Data Files

All seed data is stored in JSON files in the `data/` directory:

### `data/seed_categories.json`

Contains 12 product categories:
- Electronics (phones, computers)
- Fashion (women, men, kids)
- Home & Kitchen
- Groceries & Staples
- Agriculture & Tools
- Baby & Kids
- Sports & Outdoors
- Beauty & Health
- Automotive
- Books & Stationery

**Structure:**
```json
{
  "categories": [
    {
      "id": "electronics-phones",
      "name": "Phones & Tablets",
      "slug": "electronics-phones",
      "description": "...",
      "icon": "phone_android",
      "imageUrl": "...",
      "active": true,
      "featured": true,
      "order": 1,
      "productCount": 8,
      "metadata": {
        "color": "#2196F3",
        "showInMenu": true,
        "showInHome": true
      }
    }
  ]
}
```

### `data/seed_products.json`

Contains 54 products across all categories with complete product information.

**Key Features:**
- Product variants (color, size, storage options)
- Stock tracking by warehouse location
- Tags and metadata
- Related products
- Pricing and discounts

**Structure:**
```json
{
  "products": [
    {
      "id": "PRODUCT-ID",
      "sku": "SKU-CODE",
      "title": "Product Title",
      "description": "...",
      "price": 28999,
      "currency": "KES",
      "categoryId": "electronics-phones",
      "imageUrl": "...",
      "stock": 47,
      "tags": ["tag1", "tag2"],
      "rating": 4.3,
      "featured": true
    }
  ]
}
```

### `data/seed_inventory.json`

Inventory records for 5 key products with warehouse tracking.

**Structure:**
```json
{
  "inventory": [
    {
      "productId": "PRODUCT-ID",
      "sku": "SKU-CODE",
      "stock": 47,
      "reserved": 5,
      "lowStockThreshold": 10,
      "reorderLevel": 20,
      "locations": {
        "nairobi-warehouse": {
          "stock": 32,
          "reserved": 3,
          "aisle": "A2",
          "shelf": "12"
        }
      }
    }
  ]
}
```

### `data/seed_users.json`

Test user accounts (regular user and admin).

**Structure:**
```json
{
  "users": [
    {
      "uid": "test-user-001",
      "email": "testuser@example.com",
      "displayName": "John Mwangi",
      "role": "customer",
      "preferences": {
        "language": "en",
        "currency": "KES"
      },
      "addresses": [...]
    }
  ]
}
```

### `data/seed_home_config.json`

Dynamic home screen configuration with 8 sections.

**Structure:**
```json
{
  "homeScreen": {
    "sections": [
      {
        "id": "hero-banner",
        "type": "carousel",
        "title": "",
        "enabled": true,
        "order": 1,
        "data": {
          "banners": [...]
        }
      }
    ]
  }
}
```

## Adding New Data

### Adding a New Product

1. Open `data/seed_products.json`
2. Add a new product object to the `products` array:

```json
{
  "id": "MY-NEW-PRODUCT",
  "sku": "SKU-001",
  "title": "My New Product",
  "description": "Product description",
  "price": 1999,
  "currency": "KES",
  "categoryId": "electronics-phones",
  "imageUrl": "https://...",
  "stock": 25,
  "active": true,
  "tags": ["new", "featured"]
}
```

3. Run the seeder to add the product to Firestore

### Adding a New Category

1. Open `data/seed_categories.json`
2. Add a new category object:

```json
{
  "id": "new-category",
  "name": "New Category",
  "slug": "new-category",
  "description": "Category description",
  "icon": "category_icon",
  "active": true,
  "order": 13
}
```

3. Update products to use the new `categoryId`
4. Run the seeder

### Updating Home Screen Configuration

1. Open `data/seed_home_config.json`
2. Modify existing sections or add new ones:

```json
{
  "id": "new-section",
  "type": "product_grid",
  "title": "New Section",
  "enabled": true,
  "order": 9,
  "data": {
    "productIds": ["PRODUCT-1", "PRODUCT-2"],
    "columns": 2
  }
}
```

3. Run the seeder to update the configuration

## Troubleshooting

### Emulator Not Running

**Error:** `❌ Firestore emulator is not running!`

**Solution:** Start the emulator:
```bash
firebase emulators:start --only firestore
```

### Port Already in Use

If port 8080 is already in use, specify a different port:

```bash
export EMULATOR_PORT=9090
firebase emulators:start --only firestore --port=9090
./scripts/run_complete_seed.sh
```

### Data File Not Found

**Error:** `❌ data/seed_products.json not found`

**Solution:** Ensure you're running the seeder from the project root directory.

### Permission Errors

If you get permission errors with the shell script:

```bash
chmod +x scripts/run_complete_seed.sh
```

## Seeder Features

### Automatic Timestamps

The seeder automatically adds `createdAt` and `updatedAt` timestamps to all documents.

### Dynamic Search Terms

Products automatically get search terms generated from:
- Product title
- Description keywords
- Tags
- Category ID
- SKU

### Progress Indicators

The seeder shows real-time progress with dots (`.`) for success and `x` for failures:

```
📦 Seeding products...
..................................................
✅ Created 50 products
```

### Summary Statistics

After completion, you get a summary:

```
═══════════════════════════════════════
🎉 SEEDING COMPLETE!
═══════════════════════════════════════
Total documents created: 70
  • Categories: 12
  • Products: 54
  • Inventory: 5
  • Users: 2
  • Config: 1
═══════════════════════════════════════
```

## Best Practices

1. **Always seed in order** - The seeder handles dependencies automatically
2. **Use the emulator** - Test data changes in the emulator before production
3. **Validate JSON** - Ensure your JSON files are valid before seeding
4. **Backup data** - Keep backups of your seed files
5. **Version control** - Commit seed file changes to track data evolution

## Next Steps

After seeding:

1. Verify data in Firebase Console or emulator UI
2. Run the app and test data loading
3. Check search functionality
4. Validate home screen rendering
5. Test product filtering by category

## Related Documentation

- [Data Models](./DATA_MODELS.md) - Firestore schema documentation
- [README](../README.md) - Main project documentation
- [Firebase Setup Guide](../FIREBASE_SETUP_QUICK_REFERENCE.md) - Firebase configuration
