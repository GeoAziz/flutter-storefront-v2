# Sprint 1 Setup Guide: Firebase + Local Environment

**Sprint:** Phase 6, Sprint 1  
**Timeline:** Week 1-2 (January 13-26, 2026)  
**Team:** 2 developers  
**Objectives:** Wishlist + Comparison features ready for testing  
**Status:** 🚀 Ready to Begin

---

## Part 1: Firebase Project Configuration (Day 1)

### Step 1.1: Verify Firebase Project

Your Firebase project **`poafix`** is already created. Verify it's ready:

```bash
# Check Firebase CLI version
firebase --version

# Should show: Firebase CLI 13.x or later
```

If Firebase CLI is not installed:

```bash
npm install -g firebase-tools
firebase login
```

### Step 1.2: Initialize Firebase in Local Project

Navigate to project root and initialize:

```bash
cd /home/devmahnx/Dev/E-commerce-Complete-Flutter-UI/flutter-storefront-v2

# Initialize Firebase (if not already done)
firebase init

# Select these options:
# ✅ Firestore Database
# ✅ Cloud Functions
# ✅ Firebase Hosting (optional)
```

This creates:
- `.firebaserc` (project configuration)
- `firebase.json` (hosting/function config)
- `functions/` directory (for Cloud Functions)

### Step 1.3: Create `.env.firebase` Configuration

Create a new file in project root for local Firebase config:

```bash
cat > .env.firebase << 'EOF'
# Firebase Configuration
FIREBASE_PROJECT_ID=poafix
FIREBASE_API_KEY=AIzaSyBFNmUDrt5H0G8S5hyrDVvQfobVWbR6mkI
FIREBASE_AUTH_DOMAIN=poafix.firebaseapp.com
FIREBASE_DATABASE_URL=https://poafix-default-rtdb.firebaseio.com
FIREBASE_STORAGE_BUCKET=poafix.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=561314373498
FIREBASE_APP_ID=1:561314373498:android:1822379f2a2f7aaf7fc0c3

# Spark Plan Optimization Settings
BATCH_WRITE_SIZE=5
BATCH_WRITE_DELAY_MS=1000
CACHE_TTL_HOURS=24
ANALYTICS_BATCH_SIZE=50
ANALYTICS_FLUSH_INTERVAL_SEC=30

# Feature Flags
ENABLE_WISHLIST=true
ENABLE_COMPARISON=true
ENABLE_RECOMMENDATIONS=false
ENABLE_ANALYTICS=false
EOF

# Add to .gitignore (if not already there)
echo ".env.firebase" >> .gitignore
```

### Step 1.4: Add Firebase Dependencies to pubspec.yaml

Update `pubspec.yaml` with Firebase packages:

```yaml
dependencies:
  # ... existing dependencies ...
  firebase_core: ^2.24.0
  cloud_firestore: ^4.13.0
  firebase_auth: ^4.14.0
  firebase_storage: ^11.5.0
  firebase_remote_config: ^4.3.0

dev_dependencies:
  # ... existing dev_dependencies ...
  firebase_emulator_suite: ^0.1.0
```

Install dependencies:

```bash
flutter pub get
```

### Step 1.5: Create Firebase Service Initialization

Create `lib/services/firebase_service.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Firestore settings for optimization
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Enable offline persistence
      cacheSizeBytes: 52428800, // 50 MB cache
    );

    // Enable Firestore logging for debug
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      FirebaseFirestore.instance.enableNetwork();
    }
  }

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
}
```

### Step 1.6: Update main.dart to Initialize Firebase

Update `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  runApp(const MyApp());
}
```

---

## Part 2: Local Firebase Emulator Setup (Optional but Recommended)

### Step 2.1: Start Firebase Emulator Suite

For local development without hitting quota limits:

```bash
# Install emulator (if not already)
firebase emulators:start --project=poafix
```

This starts:
- ✅ Firestore Emulator (localhost:8080)
- ✅ Cloud Functions Emulator (localhost:5001)
- ✅ Authentication Emulator (localhost:9099)

### Step 2.2: Configure App to Use Emulator (Dev Mode)

Update `lib/services/firebase_service.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;
    
    // Use emulator in debug mode (Android only - iOS requires special setup)
    if (!const bool.fromEnvironment('dart.vm.product')) {
      if (Platform.isAndroid) {
        await firestore.useFirestoreEmulator('localhost', 8080);
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      }
    }

    // Configure Firestore settings
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 52428800, // 50 MB
    );
  }
}
```

---

## Part 3: Firestore Database Schema Setup (Day 1-2)

### Step 3.1: Create Firestore Collections

Create collections in Firebase Console or via script:

```bash
# Using Firebase CLI to create structure
firebase firestore:delete collections/users --yes
firebase firestore:delete collections/products --yes
firebase firestore:delete collections/wishlists --yes
firebase firestore:delete collections/analytics --yes
```

### Step 3.2: Create Firestore Indexes

For production queries, create these indexes in Firebase Console:

**Collection: `wishlists`**
- Index 1: `userId (Asc), createdAt (Desc)`
- Index 2: `userId (Asc), productId (Asc)`

**Collection: `analytics`**
- Index 1: `userId (Asc), timestamp (Desc)`
- Index 2: `eventType (Asc), timestamp (Desc)`

**Collection: `recommendations`**
- Index 1: `userId (Asc), score (Desc)`

### Step 3.3: Set Firestore Security Rules

Create `firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Wishlist collection
    match /wishlists/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Products collection (read-only for clients)
    match /products/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    // User profiles
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Analytics (append-only)
    match /analytics/{userId}/events/{eventId} {
      allow create: if request.auth.uid == userId;
      allow read: if false;
    }
    
    // Recommendations (read-only)
    match /recommendations/{userId}/{document=**} {
      allow read: if request.auth.uid == userId;
      allow write: if false;
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

---

## Part 4: Create Sprint 1 Feature Branch

### Step 4.1: Create and Checkout Branch

```bash
cd /home/devmahnx/Dev/E-commerce-Complete-Flutter-UI/flutter-storefront-v2

# Create branch from current feature branch
git checkout -b feat/phase-6-sprint1-wishlist-comparison

# Verify branch
git branch -v
# Should show: * feat/phase-6-sprint1-wishlist-comparison
```

### Step 4.2: Push Branch to Remote

```bash
git push -u origin feat/phase-6-sprint1-wishlist-comparison
```

### Step 4.3: Create Branch Protection (Optional)

In GitHub, go to Settings → Branches → Add rule:
- Pattern: `feat/phase-6-*`
- ✅ Require pull request reviews
- ✅ Require status checks (tests must pass)
- ✅ Require branches to be up to date

---

## Part 5: Setup Local Development Environment

### Step 5.1: Install Development Tools

```bash
# Install Dart DevTools (for profiling later)
dart pub global activate devtools

# Start DevTools
devtools
# Opens: http://localhost:9101
```

### Step 5.2: Create `.vscode/launch.json` for Debug

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter Debug",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "env": {
        "FLUTTER_LOG_LEVEL": "info"
      }
    },
    {
      "name": "Flutter Profile",
      "request": "launch",
      "type": "dart",
      "flutterMode": "profile",
      "program": "lib/main.dart"
    },
    {
      "name": "Flutter Release",
      "request": "launch",
      "type": "dart",
      "flutterMode": "release",
      "program": "lib/main.dart"
    }
  ]
}
```

### Step 5.3: Create Emulator Configuration

```bash
# List available emulators
flutter emulators

# If none available, create one
flutter emulators create --name "Pixel_5_API_30"

# Launch emulator for testing
flutter emulators launch Pixel_5_API_30
```

---

## Part 6: Verify Firebase Setup

### Step 6.1: Test Firebase Connection

Create test script `lib/main.dart` (temporary):

```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  print('✅ Firebase initialized');
  
  // Test Firestore connection
  try {
    final doc = await FirebaseService.firestore
        .collection('test')
        .doc('connection')
        .get();
    print('✅ Firestore connection successful');
  } catch (e) {
    print('❌ Firestore error: $e');
  }
  
  runApp(const MyApp());
}
```

Run app:

```bash
flutter clean
flutter pub get
flutter run -v
```

Expected output:
```
✅ Firebase initialized
✅ Firestore connection successful
```

### Step 6.2: Monitor Firebase Usage

In Firebase Console:
- Go to Firestore → Usage tab
- Set up alerts at 80% usage
- Note baseline usage before Sprint 1 starts

---

## Part 7: Daily Development Workflow

### Start of Day

```bash
# Pull latest changes from main branch
git fetch origin
git merge origin/develop

# Run tests
flutter test

# Start emulator
flutter emulators launch Pixel_5_API_30

# Run app in debug mode
flutter run -v
```

### End of Day

```bash
# Run full test suite
flutter test --coverage

# Commit changes
git add .
git commit -m "feat: [Sprint 1] Add wishlist feature - [description]"

# Push to remote
git push origin feat/phase-6-sprint1-wishlist-comparison

# Monitor Firebase usage
# Check Firebase Console for read/write counts
```

---

## Part 8: Firebase Spark Plan Budget Tracking

### Setup Daily Monitoring

Create `docs/SPRINT_1_DAILY_LOG.md`:

```markdown
# Sprint 1 Daily Firebase Usage Log

## Week 1 (January 13-17, 2026)

### Monday, January 13
- **Development:** Bootstrap Firebase, setup Hive
- **Firestore Reads:** 12
- **Firestore Writes:** 8
- **CF Invocations:** 0
- **Notes:** Initial setup and connection testing

### Tuesday, January 14
- **Development:** WishlistModel, Repository
- **Firestore Reads:** 45
- **Firestore Writes:** 12
- **CF Invocations:** 0
- **Notes:** Data model testing

### Wednesday, January 15
...
```

### Cumulative Sprint 1 Target

| Metric | Daily Avg | Sprint (10 days) | Monthly Limit | % Used |
|--------|-----------|-----------------|---------------|--------|
| **Reads** | 200 | 2,000 | 50,000 | 4% |
| **Writes** | 100 | 1,000 | 20,000 | 5% |
| **CF Invocations** | 10 | 100 | 125,000 | 0.08% |

**Goal:** Keep Sprint 1 usage < 10% of monthly limits

---

## Part 9: Troubleshooting Guide

### Issue: Firebase not connecting

```bash
# Solution 1: Check google-services.json
cat google-services.json | grep project_id

# Solution 2: Clear Flutter cache
flutter clean
flutter pub get

# Solution 3: Rebuild APK
flutter build apk --debug

# Solution 4: Check Android manifest
cat android/app/src/main/AndroidManifest.xml
```

### Issue: Firestore emulator not starting

```bash
# Check if port 8080 is available
lsof -i :8080

# Kill process if needed
kill -9 <PID>

# Restart emulator
firebase emulators:start --project=poafix
```

### Issue: Tests failing after Firebase addition

```bash
# Clear test cache
flutter test --cache
flutter test --no-test-assets
```

---

## Part 10: Checklist Before Sprint 1 Coding Begins

- [ ] Firebase project `poafix` verified in console
- [ ] `.env.firebase` created with API keys
- [ ] Firebase dependencies added to `pubspec.yaml`
- [ ] `lib/services/firebase_service.dart` created
- [ ] `lib/main.dart` updated with Firebase initialization
- [ ] Firestore collections created
- [ ] Security rules deployed
- [ ] `feat/phase-6-sprint1-wishlist-comparison` branch created
- [ ] Local emulator running (optional but recommended)
- [ ] `flutter run` succeeds with Firebase connected
- [ ] DevTools working for profiling
- [ ] Daily monitoring template created
- [ ] Team notified of Firebase setup complete

---

## Next Steps

Once this setup is complete:

1. **Day 2:** Begin implementing WishlistModel and HiveRepository
2. **Day 3-4:** Create Riverpod providers for wishlist state
3. **Day 5:** Build UI components (WishlistButton, WishlistScreen)
4. **Day 6-7:** Implement comparison features
5. **Day 8:** Run performance profile and tests
6. **Day 9-10:** Final testing and preparation for code review

**Estimated Time:** 1 full day (8 hours) for Firebase setup  
**By End of Day 1:** Everything ready for feature implementation

---

## Support

- **Firebase Documentation:** https://firebase.flutter.dev/
- **Firestore Best Practices:** https://firebase.google.com/docs/firestore/best-practices
- **Spark Plan Limits:** https://firebase.google.com/pricing

**Questions?** Refer to `PHASE_6_FIREBASE_SPARK_BUDGET.md` for cost optimization or `PHASE_6_ADVANCED_FEATURES_FIREBASE.md` for technical architecture.

---

**Last Updated:** December 16, 2025  
**Status:** ✅ Ready for Implementation  
**Next Milestone:** Sprint 1 Day 1 Kickoff - January 13, 2026

