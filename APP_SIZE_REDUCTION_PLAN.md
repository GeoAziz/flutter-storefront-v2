# App Size Reduction Plan - Phase 7 Sprint

## Current Status
- **Total Project Size**: ~2.2GB (mostly build artifacts)
- **Dependencies**: 41 direct dependencies
- **Objective**: Reduce final APK/IPA size through systematic optimization

---

## 1. DEPENDENCY AUDIT & CLEANUP

### 1.1 Current Dependency Analysis
```bash
# Check which dependencies are largest
flutter pub deps --compact

# Identify unused packages
dart pub outdated
```

### 1.2 Dependencies to Review
**High Priority (likely large)**:
- [ ] `firebase_core` + `firebase_auth` + `cloud_firestore` (Firebase suite)
- [ ] `image_picker`, `image_cropper` (image libraries)
- [ ] `google_maps_flutter` (if present - very large)
- [ ] `video_player` (if present - substantial)
- [ ] `location` (platform-specific code)
- [ ] `shared_preferences` vs `hive` vs `sqflite` (storage)

**Action Items**:
- [ ] Remove unused dependencies
- [ ] Replace heavy dependencies with lighter alternatives
- [ ] Consider conditional imports for platform-specific libs
- [ ] Consolidate overlapping functionality

---

## 2. ASSET OPTIMIZATION

### 2.1 Image Assets
```bash
# Analyze asset directories
find . -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | wc -l
du -sh assets/
```

**Optimization Strategies**:
- [ ] Convert PNG → WebP (30-40% smaller)
- [ ] Remove unused images
- [ ] Use vector graphics (SVG → Flutter vector icons)
- [ ] Implement lazy loading for non-critical images
- [ ] Use device-specific image resolutions

### 2.2 Font Files
**Action Items**:
- [ ] Remove unused font files
- [ ] Use system fonts where possible
- [ ] Only include required font weights/styles

### 2.3 Other Assets
- [ ] Remove dev/debug assets
- [ ] Compress JSON config files
- [ ] Minimize animation/lottie files

---

## 3. BUILD CONFIGURATION OPTIMIZATION

### 3.1 Android Build
**Steps**:
```bash
# In android/app/build.gradle

android {
  // Enable minification
  buildTypes {
    release {
      minifyEnabled true
      shrinkResources true
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                    'proguard-rules.pro'
    }
  }

  // Split APK by ABI (separate per architecture)
  splits {
    abi {
      enable true
      reset()
      include 'armeabi-v7a', 'arm64-v8a'
      universalApk true
    }
  }
}
```

**Checklist**:
- [ ] Enable R8/ProGuard minification
- [ ] Enable shrinkResources
- [ ] Create APK splits by ABI
- [ ] Remove unused resources in build.gradle

### 3.2 iOS Build
**Steps**:
```bash
# In ios/Podfile
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    # Enable bitcode stripping
    target.build_configurations.each do |config|
      config.build_settings['STRIP_STYLE'] = 'non-global'
    end
  end
end
```

**Checklist**:
- [ ] Enable code optimization (-Os)
- [ ] Strip debug symbols
- [ ] Use App Thinning
- [ ] Enable Bitcode

---

## 4. CODE SPLITTING & LAZY LOADING

### 4.1 Feature Modules
**Identify heavy features**:
- [ ] Payment processing screens
- [ ] Advanced product filters
- [ ] Admin panels
- [ ] Analytics dashboards

**Implementation Pattern**:
```dart
// Lazy load heavy screens
Future<void> navigateToPayment() async {
  final PaymentModule = await _loadPaymentModule();
  navigator.push(PaymentModule.screen());
}
```

### 4.2 Dynamic Feature Modules (Android)
```gradle
// android/app/build.gradle
dynamicFeatures = [":payment_feature", ":admin_feature"]
```

---

## 5. FLUTTER-SPECIFIC OPTIMIZATIONS

### 5.1 Dart Build Obfuscation
**Enable in build commands**:
```bash
# Android
flutter build apk --obfuscate --split-debug-info=./build/app/outputs/symbols

# iOS
flutter build ios --obfuscate --split-debug-info=./build/app/outputs/symbols
```

### 5.2 Remove Debug Code
**Checklist**:
- [ ] Remove print() statements → Use kDebugMode checks
- [ ] Remove debug widgets
- [ ] Disable debug banner: `debugShowCheckedModeBanner: false`
- [ ] Remove verbose logging

### 5.3 Optimize Build Targets
```bash
# Only build for required architectures
flutter build apk --target-platform android-arm64

# Check supported platforms
flutter doctor
```

---

## 6. SIZE MEASUREMENT & BENCHMARKING

### 6.1 Before/After Measurement
```bash
# Generate APK and check size
flutter build apk --release

# Check split APK sizes
ls -lh build/app/outputs/apk/release/

# For iOS
flutter build ios --release
# Check DerivedData folder
```

### 6.2 Build Size Analysis
```bash
# Analyze APK contents
unzip -l build/app/outputs/apk/release/app-release.apk | tail -20

# Check largest files
unzip -l build/app/outputs/apk/release/app-release.apk | sort -k4 -n | tail -20
```

---

## 7. IMPLEMENTATION TIMELINE

### Phase 1: Dependency Analysis (Day 1)
- [ ] Run dependency audit
- [ ] Remove unused packages
- [ ] Check for duplicate functionality
- [ ] Measure baseline APK size

### Phase 2: Asset Optimization (Days 2-3)
- [ ] Convert images to WebP
- [ ] Remove duplicate assets
- [ ] Audit font files
- [ ] Test asset loading

### Phase 3: Build Configuration (Days 4-5)
- [ ] Enable Android minification
- [ ] Set up APK splits
- [ ] Configure iOS optimizations
- [ ] Verify code obfuscation

### Phase 4: Code Optimization (Days 6-7)
- [ ] Remove debug code
- [ ] Implement lazy loading
- [ ] Profile app size
- [ ] Benchmark improvements

---

## 8. EXPECTED RESULTS

### Size Reduction Targets
- **Current Baseline**: Measure after first APK build
- **Target APK Size**: < 50MB (arm64 split)
- **Target IPA Size**: < 80MB (uncompressed)

### Typical Improvements
- Minification: 30-40% reduction
- Resource shrinking: 15-20% reduction
- WebP conversion: 20-30% reduction
- APK splitting: Per-architecture benefits

---

## 9. TRACKING & DOCUMENTATION

### Build Sizes Log
| Date | Build Type | Size | Changes | Notes |
|------|-----------|------|---------|-------|
| 2025-12-17 | Initial | ? | Baseline | To be filled |
| | After deps | | | |
| | After assets | | | |
| | After config | | | |

---

## Next Steps
1. **Immediate**: Run dependency audit
2. **Short-term**: Optimize assets
3. **Medium-term**: Configure build optimizations
4. **Long-term**: Monitor and maintain size metrics
