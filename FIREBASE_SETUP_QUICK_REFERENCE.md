# Firebase Setup Quick Reference Guide

**Project**: Flutter E-Commerce Storefront v2  
**Purpose**: Quick reference for Firebase project setup and verification  
**Last Updated**: December 16, 2025

---

## 🚀 Quick Start Commands

### 1. Firebase CLI Installation & Login (5 minutes)

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Verify installation
firebase --version

# Login to Firebase (opens browser)
firebase login

# List available projects
firebase projects:list

# Set default project
firebase use --add
```

### 2. Project Initialization (5 minutes)

```bash
# Navigate to project directory
cd /home/devmahnx/Dev/E-commerce-Complete-Flutter-UI/flutter-storefront-v2

# Initialize Firebase in project
firebase init

# When prompted, select:
# ✔ Firestore
# ✔ Authentication (if available)
# ✔ Storage (if available)
# ✔ Emulators

# Configuration files created:
# - firebase.json (Firebase configuration)
# - .firebaserc (project configuration)
```

### 3. Firestore Emulator Setup (10 minutes)

```bash
# Start emulator suite
firebase emulators:start

# Expected output:
# ⚙️  Functions emulator started at http://127.0.0.1:5001
# ✔  Firestore Emulator started at http://127.0.0.1:8080
# ✔  Auth emulator started at http://127.0.0.1:9099
```

### 4. Flutter Project Setup (10 minutes)

```bash
# Navigate to Flutter project
cd /home/devmahnx/Dev/E-commerce-Complete-Flutter-UI/flutter-storefront-v2

# Add Firebase dependencies
flutter pub add firebase_core
flutter pub add cloud_firestore
flutter pub add firebase_auth
flutter pub add firebase_storage

# Get all dependencies
flutter pub get

# Analyze code
flutter analyze

# Build for testing
flutter build apk --debug
```

---

## 📋 Verification Checklist

### GCP & Firebase Project Verification

```bash
# Verify GCP project exists
gcloud projects list | grep flutter-storefront-v2

# Verify Firebase project is linked
firebase projects:list | grep flutter-storefront-v2

# Show current project
firebase use

# Verify APIs are enabled
gcloud services list --enabled --project=[PROJECT_ID]

# Should include:
# - firestore.googleapis.com
# - firebaseauth.googleapis.com
# - firebasestorage.googleapis.com
```

### Firestore Database Verification

```bash
# Check Firestore database status
firebase database:instances:list

# List Firestore collections (when emulator is running)
curl http://127.0.0.1:8080/v1/projects/[PROJECT_ID]/databases/default/documents

# Expected response: JSON with collections structure
```

### Firebase Authentication Verification

```bash
# Verify authentication is enabled
firebase auth:export users.json

# List authentication users
firebase auth:list
```

### Storage Bucket Verification

```bash
# List storage buckets
gsutil ls

# Should show:
# gs://flutter-storefront-v2.appspot.com/
```

---

## 🔧 Configuration Files

### firebase.json

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  },
  "emulators": {
    "auth": {
      "host": "localhost",
      "port": 9099
    },
    "firestore": {
      "host": "localhost",
      "port": 8080
    },
    "storage": {
      "host": "localhost",
      "port": 4000
    },
    "ui": {
      "enabled": true,
      "host": "localhost",
      "port": 4000
    }
  }
}
```

### .firebaserc

```json
{
  "projects": {
    "default": "flutter-storefront-v2"
  },
  "targets": {},
  "etags": {}
}
```

### firestore.rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection: only owner can read/write
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /addresses/{addressId} {
        allow read, write: if request.auth.uid == userId;
      }
      
      match /preferences/{preferenceId} {
        allow read, write: if request.auth.uid == userId;
      }
    }
    
    // Products collection: everyone can read, only admins can write
    match /products/{productId} {
      allow read: if true;
      allow write: if isAdmin();
      
      match /reviews/{reviewId} {
        allow read: if true;
        allow write: if request.auth.uid != null;
      }
    }
    
    // Carts collection: only owner can read/write
    match /carts/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Orders collection: only owner can read, only owner can create new
    match /orders/{orderId} {
      allow read: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid != null;
      allow write: if isAdmin();
    }
    
    // Inventory collection: only admins can write, everyone can read
    match /inventory/{productId} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
  
  // Helper functions
  function isAdmin() {
    return request.auth.token.admin == true;
  }
  
  function isOwner(userId) {
    return request.auth.uid == userId;
  }
}
```

### firestore.indexes.json

```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "Collection",
      "fields": [
        {
          "fieldPath": "category",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "price",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "Collection",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## 🧪 Firebase Emulator Usage

### Starting Emulator

```bash
# Start all emulators
firebase emulators:start

# Start specific emulator
firebase emulators:start --only firestore

# Start with specific port
firebase emulators:start --firestore-port=8080
```

### Emulator UI

```bash
# After running firebase emulators:start
# Access UI at: http://localhost:4000

# Emulator console features:
# - View/edit Firestore collections
# - View authentication users
# - View storage files
# - Monitor real-time listeners
```

### Connecting Flutter App to Emulator

```dart
// In main.dart or initialization code
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Connect to emulator (development only)
  if (kDebugMode) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    // Also for Auth if needed:
    // FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
  
  runApp(const MyApp());
}
```

---

## 📊 Monitoring & Debugging

### Monitor Firestore Usage

```bash
# Display Firestore data
firebase firestore:inspect --json

# Clear emulator data (useful for testing)
firebase emulators:start --import ./backup --export-on-exit ./backup
```

### View Real-Time Database Activity

```bash
# Enable debug logging
firebase emulators:start --debug

# Output shows all database operations in real-time
```

### Export/Import Data

```bash
# Export data from emulator
firebase emulators:export ./backup

# Import data to emulator
firebase emulators:start --import ./backup
```

---

## 🐛 Common Issues & Solutions

### Issue: "Firebase project not initialized"

```bash
# Solution:
firebase init

# Or verify firebase.json exists:
ls -la firebase.json
```

### Issue: "Cannot connect to Firestore emulator"

```bash
# Solution: Start emulator first
firebase emulators:start

# Then in another terminal, run your app
flutter run
```

### Issue: "Firestore rules error on upload"

```bash
# Solution: Validate rules before upload
firebase firestore:rules:test

# Or check syntax in firestore.rules
firebase deploy --only firestore:rules --dry-run
```

### Issue: "Permission denied" errors in Firestore

```bash
# Solution: Check security rules
# - Use Firestore emulator UI to test rules
# - Check authentication is working
# - Verify userId matches in rules
```

### Issue: "App won't build with Firebase dependencies"

```bash
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --debug
```

---

## 🔑 Important Paths & URLs

### Local Emulator URLs
```
Firestore: http://localhost:8080
Auth: http://localhost:9099
Storage: http://localhost:4000
Emulator UI: http://localhost:4000/firestore
```

### Firebase Console URLs
```
Firebase Console: https://console.firebase.google.com/
GCP Console: https://console.cloud.google.com/
Project Settings: https://console.firebase.google.com/project/[PROJECT_ID]/settings/general/
```

### Important Local Files
```
firebase.json: /path/to/project/firebase.json
.firebaserc: /path/to/project/.firebaserc
firestore.rules: /path/to/project/firestore.rules
firestore.indexes.json: /path/to/project/firestore.indexes.json
```

---

## 📱 Flutter Firebase Integration Code Snippets

### Initialize Firebase

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

### Read from Firestore

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> readProduct(String productId) async {
  final doc = await FirebaseFirestore.instance
      .collection('products')
      .doc(productId)
      .get();
  
  if (doc.exists) {
    print('Product: ${doc.data()}');
  }
}
```

### Write to Firestore

```dart
Future<void> addToCart(String userId, String productId, int quantity) async {
  await FirebaseFirestore.instance
      .collection('carts')
      .doc(userId)
      .collection('items')
      .add({
        'productId': productId,
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(),
      });
}
```

### Real-Time Listener

```dart
void listenToUserCart(String userId) {
  FirebaseFirestore.instance
      .collection('carts')
      .doc(userId)
      .snapshots()
      .listen((snapshot) {
        if (snapshot.exists) {
          print('Cart updated: ${snapshot.data()}');
        }
      });
}
```

---

## 🚀 Deployment Checklist

Before deploying to production:

```bash
# 1. Validate Firestore rules
firebase firestore:rules:test --dry-run

# 2. Deploy Firestore rules
firebase deploy --only firestore:rules

# 3. Deploy Firestore indexes
firebase deploy --only firestore:indexes

# 4. Build Flutter app for production
flutter build apk --release

# 5. Test with production Firebase project
# - Update google-services.json with production project
# - Build and run on test device
```

---

**Document Version**: 1.0  
**Last Updated**: December 16, 2025  
**For Questions**: Contact Tech Lead or Firebase Architect
